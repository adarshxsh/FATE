from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import math

from database import get_db, LocationLog, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

class LocationData(BaseModel):
    user_id: int
    timestamp: float
    lat: float
    lng: float

# Simple Geofencing Dictionary for IIT Jodhpur
# Format: "Zone Name": {"lat": X, "lng": Y, "radius_meters": Z, "is_productive": True/False}
IIT_JODHPUR_ZONES = {
    "Library": {"lat": 26.4715, "lng": 73.1118, "radius_meters": 100, "is_productive": True},
    "Lecture Hall Complex": {"lat": 26.4728, "lng": 73.1165, "radius_meters": 150, "is_productive": True},
    "Bermuda Triangle (Canteen)": {"lat": 26.4740, "lng": 73.1130, "radius_meters": 50, "is_productive": False},
    "Hostel Area": {"lat": 26.4680, "lng": 73.1150, "radius_meters": 300, "is_productive": False}
}

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate the great circle distance in meters between two points on the earth."""
    R = 6371e3 # Earth radius in meters
    phi1 = lat1 * math.pi / 180
    phi2 = lat2 * math.pi / 180
    delta_phi = (lat2 - lat1) * math.pi / 180
    delta_lambda = (lon2 - lon1) * math.pi / 180

    a = math.sin(delta_phi/2) * math.sin(delta_phi/2) + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda/2) * math.sin(delta_lambda/2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

    return R * c

def map_location_to_zone(lat: float, lng: float):
    for zone_name, data in IIT_JODHPUR_ZONES.items():
        dist = calculate_distance(lat, lng, data["lat"], data["lng"])
        if dist <= data["radius_meters"]:
            return zone_name, data["is_productive"]
    return "Unknown Campus Area", False

@router.post("/location")
def ingest_location(data: LocationData, db: Session = Depends(get_db)):
    # Verify User
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    zone_name, is_productive = map_location_to_zone(data.lat, data.lng)

    log = LocationLog(
        user_id=data.user_id,
        timestamp=data.timestamp,
        lat=data.lat,
        lng=data.lng,
        mapped_zone=zone_name,
        is_productive_zone=is_productive
    )
    
    db.add(log)
    db.commit()
    
    return {
        "status": "success", 
        "mapped_zone": zone_name,
        "is_productive": is_productive
    }
