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

# ═══════════════════════════════════════════════════════════════
# IIT Jodhpur Permanent Campus Geofencing
# Campus center: ~26.4762°N, 73.1133°E  (Karwad, NH-62, Nagaur Rd)
#
# HOW TO UPDATE: Open Google Maps → long-press a building → copy lat/lng
# Radius is in meters. Keep generous (50-200m) to absorb GPS drift.
# ═══════════════════════════════════════════════════════════════
IIT_JODHPUR_ZONES = {
    # ── PRODUCTIVE ZONES ──
    "Library (SR Ranganathan Hub)":  {"lat": 26.4770, "lng": 73.1140, "radius_meters": 80,  "is_productive": True},
    "Lecture Hall Complex (LHC)":    {"lat": 26.4762, "lng": 73.1133, "radius_meters": 120, "is_productive": True},
    "Department Block (Academic)":   {"lat": 26.4755, "lng": 73.1145, "radius_meters": 100, "is_productive": True},
    "Central Workshop":              {"lat": 26.4748, "lng": 73.1125, "radius_meters": 60,  "is_productive": True},
    "Computer Center":               {"lat": 26.4758, "lng": 73.1155, "radius_meters": 50,  "is_productive": True},

    # ── NEUTRAL / RESIDENTIAL ZONES ──
    "Boys Hostel Area":              {"lat": 26.4730, "lng": 73.1100, "radius_meters": 250, "is_productive": False},
    "Girls Hostel Area":             {"lat": 26.4785, "lng": 73.1110, "radius_meters": 150, "is_productive": False},
    "Faculty Residences":            {"lat": 26.4800, "lng": 73.1150, "radius_meters": 200, "is_productive": False},

    # ── RECREATION / DISTRACTION ZONES ──
    "Canteen / Mess Area":           {"lat": 26.4740, "lng": 73.1130, "radius_meters": 60,  "is_productive": False},
    "Sports Complex":                {"lat": 26.4720, "lng": 73.1160, "radius_meters": 150, "is_productive": False},
    "Shopping / ATM Area":           {"lat": 26.4745, "lng": 73.1115, "radius_meters": 40,  "is_productive": False},
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
