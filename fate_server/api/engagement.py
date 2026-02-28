from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, EngagementLog, User, DailyScore

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

class EngagementData(BaseModel):
    user_id: int
    timestamp: float
    peer_device_id: str
    engagement_duration_seconds: float  # Must be > 60 to be meaningful

# Contagion Thresholds
LOW_CAS_THRESHOLD = 40.0   # Peer with CAS below this is "distracted"
HIGH_CAS_THRESHOLD = 70.0  # Peer with CAS above this is "focused"

@router.post("/engagement")
def ingest_engagement(data: EngagementData, db: Session = Depends(get_db)):
    """
    Social Contagion endpoint.
    Called by Flutter after a peer stays nearby for >1 minute.
    
    Flow:
    1. Look up peer's device_id -> find their user_id
    2. Look up peer's latest DailyScore -> get their CAS
    3. Store the engagement with the peer's CAS snapshot
    4. Return contagion verdict to Flutter for local display
    """
    # Verify reporting user
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    # Only process engagements > 60 seconds
    if data.engagement_duration_seconds < 60:
        return {"status": "ignored", "reason": "Duration too short (<1 min)"}

    # Look up the peer
    peer = db.query(User).filter(User.device_id == data.peer_device_id).first()
    
    peer_cas = None
    contagion_effect = "neutral"
    
    if peer:
        # Get peer's latest daily score
        peer_score = db.query(DailyScore).filter(
            DailyScore.user_id == peer.id
        ).order_by(DailyScore.id.desc()).first()
        
        if peer_score:
            peer_cas = peer_score.cas_score
            
            if peer_cas < LOW_CAS_THRESHOLD:
                contagion_effect = "negative"  # Peer is distracted → you get penalized
            elif peer_cas > HIGH_CAS_THRESHOLD:
                contagion_effect = "positive"  # Peer is focused → you get rewarded
    else:
        # Peer is not a FATE user — treat as neutral
        contagion_effect = "unknown_peer"

    # Persist the engagement log
    log = EngagementLog(
        user_id=data.user_id,
        peer_device_id=data.peer_device_id,
        timestamp=data.timestamp,
        engagement_duration_seconds=data.engagement_duration_seconds,
        peer_cas_at_time=peer_cas
    )
    db.add(log)
    db.commit()

    return {
        "status": "success",
        "contagion_effect": contagion_effect,
        "peer_cas": peer_cas,
        "duration_recorded": data.engagement_duration_seconds
    }
