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
    foreground_app: str

class NotificationData(BaseModel):
    timestamp: float
    package: str
    content: str

@router.post("/location")
async def ingest_location(data: LocationData):
    # In a real app we'd map (lat, lng) to a Geofence
    return {"status": "success", "recorded": data.timestamp}

@router.post("/proximity")
async def ingest_proximity(data: ProximityData):
    return {"status": "success", "recorded": data.timestamp}

@router.post("/digital")
async def ingest_digital(data: DigitalData):
    return {"status": "success", "recorded": data.timestamp}

@router.post("/notification")
async def ingest_notification(data: NotificationData):
    # Sent to Gemini for context analysis
    return {"status": "success", "recorded": data.timestamp}
