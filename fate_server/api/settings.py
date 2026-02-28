from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, User, UserPreferences

router = APIRouter(prefix="/api/settings", tags=["settings"])

class WeightsPayload(BaseModel):
    weight_spatial: float
    weight_social: float
    weight_digital: float

@router.get("/{user_id}")
def get_settings(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        # Auto-create if not exists (helpful for local dev sync)
        user = User(id=user_id, device_id=f"auto_{user_id}")
        db.add(user)
        db.commit()
        db.refresh(user)
        
    prefs = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    if not prefs:
        return {
            "status": "success",
            "weight_spatial": 0.3,
            "weight_social": 0.3,
            "weight_digital": 0.4
        }
        
    return {
        "status": "success",
        "weight_spatial": prefs.weight_spatial,
        "weight_social": prefs.weight_social,
        "weight_digital": prefs.weight_digital
    }

@router.put("/{user_id}")
def update_settings(user_id: int, data: WeightsPayload, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        # Auto-create user if app thinks it exists (DB reset case)
        user = User(id=user_id, device_id=f"auto_{user_id}")
        db.add(user)
        db.commit()
        
    # Validate sum is approx 1.0 (allow minor floating point variance like 0.99)
    total = data.weight_spatial + data.weight_social + data.weight_digital
    if abs(total - 1.0) > 0.05:
        # Normalize
        data.weight_spatial /= total
        data.weight_social /= total
        data.weight_digital /= total

    prefs = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    if not prefs:
        prefs = UserPreferences(user_id=user_id)
        db.add(prefs)
        
    prefs.weight_spatial = round(data.weight_spatial, 2)
    prefs.weight_social = round(data.weight_social, 2)
    prefs.weight_digital = round(data.weight_digital, 2)
    
    db.commit()
    
    return {
        "status": "success",
        "message": "Settings updated",
        "weight_spatial": prefs.weight_spatial,
        "weight_social": prefs.weight_social,
        "weight_digital": prefs.weight_digital
    }
