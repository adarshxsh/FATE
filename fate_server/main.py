from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base

# Create DB Tables
Base.metadata.create_all(bind=engine)

from api import auth, location, digital, proximity, notifications, engagement, friends, analysis, settings
from core import scoring

app = FastAPI(title="FATE Telemetry Server", description="Deterministic CAS Scoring Engine")

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

@app.get("/")
def read_root():
    return {"status": "Active", "engine": "Deterministic CAS v2"}

@app.get("/api/dashboard/{user_id}")
def get_dashboard(user_id: int):
    """
    Hit by Flutter to get the fully computed CAS and sub-scores.
    Triggers a fresh recalculation from all stored telemetry.
    """
    from database import SessionLocal
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
4