from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base

# Create DB Tables
Base.metadata.create_all(bind=engine)

from api import auth, location, digital, proximity, notifications
from core import scoring

app = FastAPI(title="FATE Telemetry Server", description="Algorithmic MVP Backend")

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

@app.get("/")
def read_root():
    return {"status": "Active", "engine": "Algorithmic CAS"}

@app.get("/api/dashboard/{user_id}")
def get_dashboard(user_id: int):
    # This endpoint can be hit by Flutter to get perfectly compiled scores
    from database import SessionLocal
    db = SessionLocal()
    try:
        score_record = scoring.calculate_daily_cas(user_id, db)
        return {
            "cas_score": score_record.cas_score,
            "spatial_score": score_record.spatial_score,
            "digital_score": score_record.digital_score,
            "social_score": score_record.social_score
        }
    finally:
        db.close()
