"""Tests for the v2 community API.  Run: cd fate_server && pytest -q test_community.py"""

import os
import tempfile
import time

_db_file = tempfile.NamedTemporaryFile(suffix=".db", delete=False).name
os.environ["DATABASE_URL"] = f"sqlite:///{_db_file}"

from fastapi.testclient import TestClient  # noqa: E402

import database  # noqa: E402
from api import community  # noqa: E402
from main import app  # noqa: E402

client = TestClient(app)
_n = 0


def register(name="user"):
    global _n
    _n += 1
    r = client.post("/api/v2/register", json={
        "local_id": f"local-{_n:08d}", "bluetooth_id": f"ble{_n:05d}", "display_name": name,
    })
    assert r.status_code == 201, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}, f"ble{_n:05d}"


def test_health_and_legacy_disabled():
    assert client.get("/healthz").json() == {"ok": True}
    assert client.post("/api/auth/register", json={"device_id": "x"}).status_code == 404
    assert client.get("/api/dashboard/1").status_code == 404


def test_auth_required():
    assert client.get("/api/v2/community").status_code == 401
    assert client.get("/api/v2/community", headers={"Authorization": "Bearer nope"}).status_code == 401


def test_duplicate_registration_rejected():
    body = {"local_id": "dup-local-1", "bluetooth_id": "dupble1"}
    assert client.post("/api/v2/register", json=body).status_code == 201
    assert client.post("/api/v2/register", json=body).status_code == 409
    # bluetooth_id collision alone is also rejected
    assert client.post("/api/v2/register", json={"local_id": "dup-local-2", "bluetooth_id": "dupble1"}).status_code == 409


def test_peer_cas_drives_contagion():
    alice, _ = register("alice")
    bob, bob_ble = register("bob")

    # Unknown peer -> no CAS, effect unknown (this was hardcoded to 50.0 before)
    r = client.post("/api/v2/engagements", headers=alice, json={"peer_bluetooth_id": "nobody00", "duration_seconds": 120})
    assert r.json() == {"peer_known": False, "peer_cas": None, "effect": "unknown"}

    # Known peer without a score yet
    r = client.post("/api/v2/engagements", headers=alice, json={"peer_bluetooth_id": bob_ble, "duration_seconds": 120})
    assert r.json()["peer_known"] is True and r.json()["effect"] == "unknown"

    client.post("/api/v2/scores", headers=bob, json={"cas": 82, "s_loc": 1, "s_soc": 1, "s_dig": 70})
    assert client.get(f"/api/v2/peers/{bob_ble}", headers=alice).json()["cas"] == 82
    r = client.post("/api/v2/engagements", headers=alice, json={"peer_bluetooth_id": bob_ble, "duration_seconds": 300})
    assert r.json() == {"peer_known": True, "peer_cas": 82, "effect": "positive"}


def test_offline_replay_uses_cas_at_engagement_time():
    alice, _ = register("alice2")
    bob, bob_ble = register("bob2")
    client.post("/api/v2/scores", headers=bob, json={"cas": 30, "s_loc": 0, "s_soc": 0, "s_dig": 30})
    ended_at = time.time()
    # Bob's score improves later, after the snapshot interval
    with database.SessionLocal() as db:
        db.query(database.ScoreSnapshot).update({"timestamp": ended_at - 120})
        db.commit()
    client.post("/api/v2/scores", headers=bob, json={"cas": 90, "s_loc": 0, "s_soc": 0, "s_dig": 90})
    r = client.post("/api/v2/engagements", headers=alice, json={
        "peer_bluetooth_id": bob_ble, "duration_seconds": 600, "ended_at": ended_at - 60,
    })
    assert r.json()["peer_cas"] == 30 and r.json()["effect"] == "negative"


def test_self_engagement_and_stale_rejected():
    alice, alice_ble = register("selfie")
    assert client.post("/api/v2/engagements", headers=alice, json={"peer_bluetooth_id": alice_ble, "duration_seconds": 90}).status_code == 422
    assert client.post("/api/v2/engagements", headers=alice, json={
        "peer_bluetooth_id": "someone1", "duration_seconds": 90, "ended_at": time.time() - 3 * 86400,
    }).status_code == 422


def test_snapshot_flood_collapses():
    alice, _ = register("flood")
    for c in range(10):
        client.post("/api/v2/scores", headers=alice, json={"cas": 50 + c, "s_loc": 0, "s_soc": 0, "s_dig": 50})
    with database.SessionLocal() as db:
        me = db.query(database.CommunityDevice).filter_by(display_name="flood").one()
        snaps = db.query(database.ScoreSnapshot).filter_by(device_id=me.id).all()
    assert len(snaps) == 1 and snaps[0].cas == 59


def test_community_zone_k_anonymity_and_percentile():
    headers = [register(f"z{i}")[0] for i in range(4)]
    for i, h in enumerate(headers[:3]):
        client.post("/api/v2/scores", headers=h, json={"cas": 60 + i, "s_loc": 0, "s_soc": 0, "s_dig": 50, "zone": "LHC"})
    client.post("/api/v2/scores", headers=headers[3], json={"cas": 10, "s_loc": 0, "s_soc": 0, "s_dig": 10, "zone": "KT"})

    body = client.get("/api/v2/community", headers=headers[2]).json()
    zones = {z["zone"]: z for z in body["zones"]}
    assert "LHC" in zones and zones["LHC"]["members"] >= 3
    assert "KT" not in zones  # a lone member's location must not leak
    assert body["my_cas"] == 62 and body["my_percentile"] is not None


def test_delete_me_erases():
    alice, alice_ble = register("gone")
    bob, _ = register("watcher")
    client.post("/api/v2/scores", headers=alice, json={"cas": 70, "s_loc": 0, "s_soc": 0, "s_dig": 70})
    assert client.delete("/api/v2/me", headers=alice).status_code == 204
    assert client.get("/api/v2/community", headers=alice).status_code == 401
    assert client.get(f"/api/v2/peers/{alice_ble}", headers=bob).json() == {"known": False}


def test_constants_sane():
    assert community.LOW_CAS < community.HIGH_CAS
