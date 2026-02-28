from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

# We import the tables to extend them if needed, but for MVP we might just log this to digital logs
from database import get_db, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

class NotificationData(BaseModel):
    user_id: int
    timestamp: float
    package: str
    content: str
    
# Hardcoded messaging heuristics for MVP Algorithm
MESSAGING_APPS = [
    "com.whatsapp",
    "org.telegram.messenger",
    "com.facebook.orca", # Messenger
    "com.discord"
]

@router.post("/notification")
def ingest_notification(data: NotificationData, db: Session = Depends(get_db)):
    # Verify User
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    # In a full production system you would link this to a NotificationLog table.
    # For MVP, we determine if it's a high-interruption message.
    is_messaging = data.package in MESSAGING_APPS
    
    # We could trigger the Attention Engine scoring penalty here based on 
    # the sheer frequency of notifications within a 5-minute window!
    
    return {
        "status": "success", 
        "is_messaging_interruption": is_messaging
    }
