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
    periods_count: int = 1  # Number of 2-minute detection intervals spent at this location

# ═══════════════════════════════════════════════════════════════
# IIT Jodhpur Permanent Campus Geofencing
# Campus center: ~26.4762°N, 73.1133°E  (Karwad, NH-62, Nagaur Rd)
#
# HOW TO UPDATE: Open Google Maps → long-press a building → copy lat/lng
# Radius is in meters. Keep generous (50-200m) to absorb GPS drift.
# ═══════════════════════════════════════════════════════════════
IIT_JODHPUR_ZONES = {
    # ── PRODUCTIVE ──
    "New Mess":                           {"lat": 26.473123, "lng": 73.114013, "radius_meters": 150, "is_productive": True},
    # ── NEUTRAL (hostel / off-campus) — no score impact ──
    "Hostel Area":                   {"lat": 26.4730, "lng": 73.1100, "radius_meters": 300, "is_productive": False, "score_neutral": True},
    # ── DISTRACTION ──
    "Shamiana":                      {"lat": 26.4768079, "lng": 73.1142273, "radius_meters": 150, "is_productive": False},
    "LHC 1":                      {"lat": 26.4728026, "lng": 73.1173692, "radius_meters": 150, "is_productive": False},
    "Akash Complex":                 {"lat": 26.4768229, "lng": 73.1197027, "radius_meters": 150, "is_productive": False},
    "KT":                            {"lat": 26.4693031, "lng": 73.1141130, "radius_meters": 150, "is_productive": False},
    "FNG":                           {"lat": 26.4662537, "lng": 73.1119672, "radius_meters": 150, "is_productive": False},
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
    """Return (zone_name, is_productive, score_neutral) for the given coordinates."""
    for zone_name, data in IIT_JODHPUR_ZONES.items():
        dist = calculate_distance(lat, lng, data["lat"], data["lng"])
        if dist <= data["radius_meters"]:
            neutral = data.get("score_neutral", False)
            return zone_name, data["is_productive"], neutral
    return "Unknown Campus Area", False, True  # Off-campus — neutral, no penalty

@router.post("/location")
def ingest_location(data: LocationData, db: Session = Depends(get_db)):
    try:
        # Verify User
        user = db.query(User).filter(User.id == data.user_id).first()
        if not user:
            return {"status": "error", "message": "User not found"}

        zone_name, is_productive, is_neutral = map_location_to_zone(data.lat, data.lng)

        # Convert periods_count to minutes spent (each period = 2 minutes)
        minutes_spent = data.periods_count * 2

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
            "is_productive": is_productive,
            "is_neutral": is_neutral,        # Hostel / off-campus — no CAS impact
            "minutes_spent": minutes_spent,
        }
    except Exception as e:
        print(f"ERROR in ingest_location: {e}")
        return {"status": "error", "message": str(e)}
