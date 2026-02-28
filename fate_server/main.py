from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base, SessionLocal, get_db
from database import LocationLog, DigitalLog, ProximityLog, NotificationLog, EngagementLog
from contextlib import asynccontextmanager
import threading
import time
import datetime

# Create DB Tables
Base.metadata.create_all(bind=engine)

from api import auth, location, digital, proximity, notifications, engagement, friends, analysis, settings, device_mapping
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

# Register API Routers
app.include_router(auth.router)
app.include_router(location.router)
app.include_router(digital.router)
app.include_router(proximity.router)
app.include_router(notifications.router)
app.include_router(engagement.router)
app.include_router(friends.router)
app.include_router(analysis.router)
app.include_router(settings.router)
app.include_router(device_mapping.router)

@app.get("/")
def read_root():
    return {"status": "Active", "engine": "Deterministic CAS v2"}

@app.get("/api/dashboard/{user_id}")
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


@app.post("/api/gc/run")
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