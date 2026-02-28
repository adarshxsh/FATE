from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database import get_db, User
import datetime

router = APIRouter(prefix="/api/auth", tags=["auth"])

class DeviceRegistration(BaseModel):
    device_id: str
    firebase_uid: str | None = None
    username: str | None = None

class AuthResponse(BaseModel):
    status: str
    user_id: int
    message: str

@router.post("/register", response_model=AuthResponse)
def register_device(data: DeviceRegistration, db: Session = Depends(get_db)):
    # Check if device already registered
    existing_user = db.query(User).filter(User.device_id == data.device_id).first()
    
    if existing_user:
        # Optionally update firebase_uid if it wasn't set
        if data.firebase_uid and not existing_user.firebase_uid:
            existing_user.firebase_uid = data.firebase_uid
            db.commit()
            
        return AuthResponse(
            status="success", 
            user_id=existing_user.id, 
            message="Device already registered."
        )
    
    # Create new user
    new_user = User(
        device_id=data.device_id,
        firebase_uid=data.firebase_uid,
        username=data.username
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return AuthResponse(
        status="success", 
        user_id=new_user.id, 
        message="Device registered successfully."
    )
