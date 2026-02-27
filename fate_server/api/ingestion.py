from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

router = APIRouter()

class LocationData(BaseModel):
    timestamp: float
    lat: float
    lng: float

class ProximityData(BaseModel):
    timestamp: float
    nearby_peers: int

class DigitalData(BaseModel):
    timestamp: float
    app_category: str
    usage_duration_seconds: float

class NotificationData(BaseModel):
    timestamp: float
    app_category: str
    content: str
    response_time_seconds: float | None = None  # None implies it was ignored or dismissed

@router.post("/location")
async def ingest_location(data: LocationData):
    # In a real app we'd map (lat, lng) to a Geofence
    return {"status": "success", "recorded": data.timestamp}

@router.post("/proximity")
async def ingest_proximity(data: ProximityData):
    return {"status": "success", "recorded": data.timestamp}

@router.post("/digital")
async def ingest_digital(data: DigitalData):
    # In a real app we'd fetch this score from core/scoring.py
    return {"status": "success", "recorded": data.timestamp, "duration_recorded": data.usage_duration_seconds}

@router.post("/notification")
async def ingest_notification(data: NotificationData):
    # Sent to Gemini for context analysis
    return {"status": "success", "recorded": data.timestamp}
