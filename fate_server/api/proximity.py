from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, ProximityLog, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

class ProximityData(BaseModel):
    user_id: int
    timestamp: float
    nearby_peers: int
    peer_name: str | None = None

@router.post("/proximity")
def ingest_proximity(data: ProximityData, db: Session = Depends(get_db)):
    # Verify User
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    log = ProximityLog(
        user_id=data.user_id,
        timestamp=data.timestamp,
        nearby_peers_count=data.nearby_peers,
        peer_name=data.peer_name
    )
    
    db.add(log)
    db.commit()
    
    return {"status": "success", "peers_recorded": data.nearby_peers}
