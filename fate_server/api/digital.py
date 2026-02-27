from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, DigitalLog, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

class DigitalData(BaseModel):
    user_id: int
    timestamp: float
    package: str
    duration: int

# Hardcoded distraction heuristics for MVP Algorithm
DISTRACTING_APPS = [
    "com.instagram.android", 
    "com.zhiliaoapp.musically", # TikTok
    "com.snapchat.android",
    "com.facebook.katana",
    "com.twitter.android",
    "com.google.android.youtube",
    "com.netflix.mediaclient"
]

@router.post("/digital")
def ingest_digital(data: DigitalData, db: Session = Depends(get_db)):
    # Verify User
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    is_distracting = data.package in DISTRACTING_APPS

    log = DigitalLog(
        user_id=data.user_id,
        timestamp=data.timestamp,
        package_name=data.package,
        duration_ms=data.duration,
        is_distracting=is_distracting
    )
    
    db.add(log)
    db.commit()
    
    return {
        "status": "success", 
        "is_distracting": is_distracting
    }
