from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List
from core.database import get_db

router = APIRouter()

class LocationData(BaseModel):
    user_email: str = "test@iitj.ac.in"
    timestamp: float
    lat: float
    lng: float

class ProximityData(BaseModel):
    user_email: str = "test@iitj.ac.in"
    timestamp: float
    nearby_peers: int

class DigitalData(BaseModel):
    user_email: str = "test@iitj.ac.in"
    timestamp: float
    app_category: str
    usage_duration_seconds: float

class NotificationData(BaseModel):
    user_email: str = "test@iitj.ac.in"
    timestamp: float
    app_category: str
    content: str
    response_time_seconds: float | None = None  # None implies it was ignored or dismissed

@router.post("/location")
def ingest_location(data: LocationData, db = Depends(get_db)):
    if db:
        db.collection("location_logs").add(data.model_dump())
    return {"status": "success", "recorded": data.timestamp}

@router.post("/proximity")
def ingest_proximity(data: ProximityData, db = Depends(get_db)):
    if db:
        db.collection("proximity_logs").add(data.model_dump())
    return {"status": "success", "recorded": data.timestamp}

@router.post("/digital")
def ingest_digital(data: DigitalData, db = Depends(get_db)):
    if db:
        db.collection("digital_logs").add(data.model_dump())
    return {"status": "success", "recorded": data.timestamp, "duration_recorded": data.usage_duration_seconds}

@router.post("/notification")
def ingest_notification(data: NotificationData, db = Depends(get_db)):
    if db:
        db.collection("notification_logs").add(data.model_dump())
    return {"status": "success", "recorded": data.timestamp}
