from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
import models.domain as models
import datetime

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
async def ingest_location(data: LocationData, db: AsyncSession = Depends(get_db)):
    db_log = models.LocationLog(user_email=data.user_email, timestamp=data.timestamp, lat=data.lat, lng=data.lng)
    db.add(db_log)
    await db.commit()
    return {"status": "success", "recorded": data.timestamp}

@router.post("/proximity")
async def ingest_proximity(data: ProximityData, db: AsyncSession = Depends(get_db)):
    db_log = models.ProximityLog(user_email=data.user_email, timestamp=data.timestamp, nearby_peers=data.nearby_peers)
    db.add(db_log)
    await db.commit()
    return {"status": "success", "recorded": data.timestamp}

@router.post("/digital")
async def ingest_digital(data: DigitalData, db: AsyncSession = Depends(get_db)):
    db_log = models.DigitalLog(
        user_email=data.user_email,
        timestamp=data.timestamp,
        app_category=data.app_category,
        usage_duration_seconds=data.usage_duration_seconds
    )
    db.add(db_log)
    await db.commit()
    return {"status": "success", "recorded": data.timestamp, "duration_recorded": data.usage_duration_seconds}

@router.post("/notification")
async def ingest_notification(data: NotificationData, db: AsyncSession = Depends(get_db)):
    db_log = models.NotificationLog(
        user_email=data.user_email,
        timestamp=data.timestamp,
        app_category=data.app_category,
        content=data.content,
        response_time_seconds=data.response_time_seconds
    )
    db.add(db_log)
    await db.commit()
    return {"status": "success", "recorded": data.timestamp}
