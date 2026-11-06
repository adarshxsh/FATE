"""Community API (v2).

The v2 app is local-first: raw location / app usage / notification logs never
leave the phone. A single phone can't measure how attention moves through a
group, though. It can't know a nearby peer's CAS, and it can't see campus-wide
patterns. This router holds only that cross-device state:

  * score snapshots  (CAS + sub-scores, optional coarse zone)
  * engagement edges (A was near B for N seconds; B's CAS at the time)
  * campus aggregates derived from the two

Auth: each install registers once and gets a random bearer token. Only its
sha256 is stored. The broadcast bluetooth_id is public by design, so it is
never accepted as proof of identity.
"""

import hashlib
import secrets
import time

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import CommunityDevice, CommunityEngagement, ScoreSnapshot, get_db

router = APIRouter(prefix="/api/v2", tags=["community"])

# A peer's score older than this is treated as unknown rather than applied.
PEER_CAS_MAX_AGE_SECS = 6 * 3600
# Snapshots closer together than this overwrite the latest row instead of
# appending, so a misbehaving client can't flood the table.
SNAPSHOT_MIN_INTERVAL_SECS = 60
# Zones with fewer distinct members than this are hidden from the campus view
# so a single person's whereabouts can't be read off the aggregate.
ZONE_K_ANONYMITY = 3
LOW_CAS = 40.0
HIGH_CAS = 70.0
DAY = 86400


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def current_device(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> CommunityDevice:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    device = (
        db.query(CommunityDevice)
        .filter(CommunityDevice.token_hash == _hash(authorization[7:]))
        .first()
    )
    if device is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    device.last_seen = time.time()
    return device


def _latest_cas(db: Session, device_id: int, at: float) -> tuple[float | None, float | None]:
    """Peer's most recent CAS at or before `at`, if fresh enough."""
    snap = (
        db.query(ScoreSnapshot)
        .filter(
            ScoreSnapshot.device_id == device_id,
            ScoreSnapshot.timestamp <= at,
            ScoreSnapshot.timestamp >= at - PEER_CAS_MAX_AGE_SECS,
        )
        .order_by(ScoreSnapshot.timestamp.desc())
        .first()
    )
    return (snap.cas, snap.timestamp) if snap else (None, None)


# ── Registration ─────────────────────────────────────────

class RegisterRequest(BaseModel):
    local_id: str = Field(min_length=8, max_length=64)
    bluetooth_id: str = Field(min_length=4, max_length=64)
    display_name: str | None = Field(default=None, max_length=64)


class RegisterResponse(BaseModel):
    device_id: int
    token: str


@router.post("/register", response_model=RegisterResponse, status_code=201)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    token = secrets.token_urlsafe(32)
    device = CommunityDevice(
        local_id=data.local_id,
        bluetooth_id=data.bluetooth_id,
        display_name=data.display_name,
        token_hash=_hash(token),
        last_seen=time.time(),
    )
    db.add(device)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # Re-issuing a token for an existing local_id would let anyone who
        # learns it take over the identity; the app generates a fresh
        # local_id + bluetooth_id on reinstall instead.
        raise HTTPException(status_code=409, detail="Device already registered")
    db.refresh(device)
    return RegisterResponse(device_id=device.id, token=token)


class ProfileUpdate(BaseModel):
    display_name: str | None = Field(default=None, max_length=64)


@router.patch("/me")
def update_me(data: ProfileUpdate, me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    me.display_name = data.display_name
    db.commit()
    return {"status": "ok"}


@router.delete("/me", status_code=204)
def delete_me(me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    """Right to erasure: drops the device, its snapshots and edges it reported."""
    db.query(ScoreSnapshot).filter(ScoreSnapshot.device_id == me.id).delete()
    db.query(CommunityEngagement).filter(CommunityEngagement.reporter_id == me.id).delete()
    db.query(CommunityEngagement).filter(CommunityEngagement.peer_id == me.id).update({"peer_id": None})
    db.delete(me)
    db.commit()


# ── Scores ───────────────────────────────────────────────

class ScoreIn(BaseModel):
    cas: float = Field(ge=0, le=100)
    s_loc: float
    s_soc: float
    s_dig: float = Field(ge=0, le=100)
    zone: str | None = Field(default=None, max_length=64)


@router.post("/scores")
def publish_score(data: ScoreIn, me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    now = time.time()
    last = (
        db.query(ScoreSnapshot)
        .filter(ScoreSnapshot.device_id == me.id)
        .order_by(ScoreSnapshot.timestamp.desc())
        .first()
    )
    if last and now - last.timestamp < SNAPSHOT_MIN_INTERVAL_SECS:
        snap = last
    else:
        snap = ScoreSnapshot(device_id=me.id)
        db.add(snap)
    snap.timestamp = now
    snap.cas, snap.s_loc, snap.s_soc, snap.s_dig = data.cas, data.s_loc, data.s_soc, data.s_dig
    snap.zone = data.zone
    db.commit()
    return {"status": "ok"}


# ── Peers ────────────────────────────────────────────────

@router.get("/peers/{bluetooth_id}")
def lookup_peer(bluetooth_id: str, me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    peer = db.query(CommunityDevice).filter(CommunityDevice.bluetooth_id == bluetooth_id).first()
    db.commit()  # persist last_seen
    if peer is None:
        return {"known": False}
    cas, cas_at = _latest_cas(db, peer.id, time.time())
    return {"known": True, "display_name": peer.display_name, "cas": cas, "cas_at": cas_at}


class EngagementIn(BaseModel):
    peer_bluetooth_id: str = Field(min_length=4, max_length=64)
    duration_seconds: float = Field(gt=0, le=DAY)
    ended_at: float | None = None  # epoch secs; defaults to now (offline replays send the real time)


@router.post("/engagements")
def report_engagement(data: EngagementIn, me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    now = time.time()
    ended_at = min(data.ended_at or now, now)
    if ended_at < now - 2 * DAY:
        raise HTTPException(status_code=422, detail="Engagement too old")
    if data.peer_bluetooth_id == me.bluetooth_id:
        raise HTTPException(status_code=422, detail="Cannot engage with self")

    peer = db.query(CommunityDevice).filter(CommunityDevice.bluetooth_id == data.peer_bluetooth_id).first()
    peer_cas = _latest_cas(db, peer.id, ended_at)[0] if peer else None

    db.add(CommunityEngagement(
        reporter_id=me.id,
        peer_id=peer.id if peer else None,
        peer_bluetooth_id=data.peer_bluetooth_id,
        ended_at=ended_at,
        duration_seconds=data.duration_seconds,
        peer_cas=peer_cas,
    ))
    db.commit()

    if peer_cas is None:
        effect = "unknown"
    elif peer_cas < LOW_CAS:
        effect = "negative"
    elif peer_cas > HIGH_CAS:
        effect = "positive"
    else:
        effect = "neutral"
    return {"peer_known": peer is not None, "peer_cas": peer_cas, "effect": effect}


# ── Campus aggregate ─────────────────────────────────────

@router.get("/community")
def community(me: CommunityDevice = Depends(current_device), db: Session = Depends(get_db)):
    since = time.time() - DAY

    # Each member's latest snapshot in the window.
    latest_ts = (
        db.query(ScoreSnapshot.device_id, func.max(ScoreSnapshot.timestamp).label("ts"))
        .filter(ScoreSnapshot.timestamp >= since)
        .group_by(ScoreSnapshot.device_id)
        .subquery()
    )
    latest = (
        db.query(ScoreSnapshot)
        .join(latest_ts, (ScoreSnapshot.device_id == latest_ts.c.device_id) & (ScoreSnapshot.timestamp == latest_ts.c.ts))
        .all()
    )
    cas_values = [s.cas for s in latest]
    mine = next((s.cas for s in latest if s.device_id == me.id), None)
    percentile = None
    if mine is not None and len(cas_values) > 1:
        below = sum(1 for c in cas_values if c < mine)
        percentile = round(100.0 * below / (len(cas_values) - 1), 1)

    # Zone view: average of every snapshot in the window, per zone, k-anonymised.
    zone_rows = (
        db.query(
            ScoreSnapshot.zone,
            func.count(func.distinct(ScoreSnapshot.device_id)),
            func.avg(ScoreSnapshot.cas),
        )
        .filter(ScoreSnapshot.timestamp >= since, ScoreSnapshot.zone.isnot(None))
        .group_by(ScoreSnapshot.zone)
        .all()
    )
    zones = sorted(
        (
            {"zone": z, "members": n, "avg_cas": round(avg, 1)}
            for z, n, avg in zone_rows
            if n >= ZONE_K_ANONYMITY
        ),
        key=lambda r: r["avg_cas"],
        reverse=True,
    )

    # Contagion edges in the window.
    edges = db.query(CommunityEngagement).filter(CommunityEngagement.ended_at >= since).all()
    positive = sum(1 for e in edges if e.peer_cas is not None and e.peer_cas > HIGH_CAS)
    negative = sum(1 for e in edges if e.peer_cas is not None and e.peer_cas < LOW_CAS)
    my_edges = [e for e in edges if e.reporter_id == me.id]

    db.commit()  # persist last_seen
    return {
        "window_hours": 24,
        "active_members": len(cas_values),
        "avg_cas": round(sum(cas_values) / len(cas_values), 1) if cas_values else None,
        "my_cas": mine,
        "my_percentile": percentile,
        "zones": zones,
        "engagements": {
            "total": len(edges),
            "positive": positive,
            "negative": negative,
            "mine": len(my_edges),
            "my_minutes": round(sum(e.duration_seconds for e in my_edges) / 60.0, 1),
        },
    }
