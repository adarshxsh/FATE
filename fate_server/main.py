from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base, SessionLocal, get_db
from database import LocationLog, DigitalLog, ProximityLog, NotificationLog, EngagementLog
from database import ScoreSnapshot, CommunityEngagement
import os
from contextlib import asynccontextmanager
import threading
import time
import datetime

# Create DB Tables
Base.metadata.create_all(bind=engine)

from api import auth, location, digital, proximity, notifications, engagement, friends, analysis, settings, device_mapping
from api import community
from core import scoring


# ── Daily Garbage Collection ──────────────────────────────
def run_daily_gc():
    """Delete raw telemetry logs older than 24 hours.
    DailyScore summaries are KEPT forever."""
    while True:
        now = datetime.datetime.utcnow()
        # Sleep until next midnight UTC
        tomorrow = (now + datetime.timedelta(days=1)).replace(hour=0, minute=5, second=0)
        sleep_secs = (tomorrow - now).total_seconds()
        time.sleep(sleep_secs)

        print(f"[GC] Running daily garbage collection at {datetime.datetime.utcnow()}")
        db = SessionLocal()
        try:
            cutoff = time.time() - 86400  # 24 hours ago (epoch)
            for LogModel in [LocationLog, DigitalLog, ProximityLog, NotificationLog, EngagementLog]:
                deleted = db.query(LogModel).filter(LogModel.timestamp < cutoff).delete()
                print(f"[GC] Deleted {deleted} rows from {LogModel.__tablename__}")
            # Community layer keeps 30 days so weekly trends are possible.
            community_cutoff = time.time() - 30 * 86400
            db.query(ScoreSnapshot).filter(ScoreSnapshot.timestamp < community_cutoff).delete()
            db.query(CommunityEngagement).filter(CommunityEngagement.ended_at < community_cutoff).delete()
            db.commit()
            print("[GC] Garbage collection complete.")
        except Exception as e:
            db.rollback()
            print(f"[GC] Error: {e}")
        finally:
            db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Start background GC thread on server boot."""
    gc_thread = threading.Thread(target=run_daily_gc, daemon=True)
    gc_thread.start()
    print("[GC] Background garbage collector scheduled.")
    yield


app = FastAPI(
    title="FATE Telemetry Server",
    description="Deterministic CAS Scoring Engine",
    lifespan=lifespan,
)

# Enable CORS for the mobile client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# v2 community API: what the local-first app talks to.
app.include_router(community.router)

# v1 raw-telemetry API. Unauthenticated and keyed by a guessable integer
# user_id, so anyone can read or write any user's data. The v2 app doesn't
# call it; it stays off unless explicitly enabled for the old app build.
ENABLE_LEGACY_API = os.getenv("ENABLE_LEGACY_API", "false").lower() == "true"
if ENABLE_LEGACY_API:
    for r in (auth, location, digital, proximity, notifications, engagement,
              friends, analysis, settings, device_mapping):
        app.include_router(r.router)

@app.get("/")
def read_root():
    return {"status": "Active", "engine": "Deterministic CAS v2"}


@app.get("/healthz")
def healthz():
    """Render health check: also proves the DB is reachable."""
    from sqlalchemy import text
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"ok": True}


def get_dashboard(user_id: int):
    """
    Hit by Flutter to get the fully computed CAS and sub-scores.
    Triggers a fresh recalculation from all stored telemetry.
    """
    db = SessionLocal()
    try:
        record = scoring.calculate_daily_cas(user_id, db)
        return {
            "CAS": round(record.cas_score, 2),
            "S_loc": round(record.spatial_score, 2),
            "S_soc": round(record.social_score, 2),
            "S_dig": round(record.digital_score, 2),
        }
    finally:
        db.close()


def manual_gc():
    """Manual trigger for garbage collection (for testing)."""
    db = SessionLocal()
    try:
        cutoff = time.time() - 86400
        total = 0
        for LogModel in [LocationLog, DigitalLog, ProximityLog, NotificationLog, EngagementLog]:
            deleted = db.query(LogModel).filter(LogModel.timestamp < cutoff).delete()
            total += deleted
        db.commit()
        return {"status": "success", "rows_deleted": total}
    except Exception as e:
        db.rollback()
        return {"status": "error", "message": str(e)}
    finally:
        db.close()


if ENABLE_LEGACY_API:
    app.add_api_route("/api/dashboard/{user_id}", get_dashboard, methods=["GET"])
    app.add_api_route("/api/gc/run", manual_gc, methods=["POST"])
