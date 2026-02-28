from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, DeviceMapping, User

router = APIRouter(prefix="/api/device_mapping", tags=["device_mapping"])

class DeviceMappingData(BaseModel):
    user_id: int
    google_name: str
    bluetooth_id: str

@router.post("/")
def update_mapping(data: DeviceMappingData, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}
        
    mapping = db.query(DeviceMapping).filter(DeviceMapping.user_id == data.user_id).first()
    if mapping:
        mapping.google_name = data.google_name
        mapping.bluetooth_id = data.bluetooth_id
    else:
        mapping = DeviceMapping(
            user_id=data.user_id,
            google_name=data.google_name,
            bluetooth_id=data.bluetooth_id
        )
        db.add(mapping)
    db.commit()
    return {"status": "success"}

@router.get("/{bluetooth_id}")
def get_mapping(bluetooth_id: str, db: Session = Depends(get_db)):
    mapping = db.query(DeviceMapping).filter(DeviceMapping.bluetooth_id == bluetooth_id).first()
    if mapping:
        return {
            "status": "success",
            "user_id": mapping.user_id,
            "google_name": mapping.google_name,
            "bluetooth_id": mapping.bluetooth_id
        }
    return {"status": "error", "message": "Not found"}

@router.get("/user/{user_id}")
def get_mapping_by_user(user_id: int, db: Session = Depends(get_db)):
    mapping = db.query(DeviceMapping).filter(DeviceMapping.user_id == user_id).first()
    if mapping:
        return {
            "status": "success",
            "user_id": mapping.user_id,
            "google_name": mapping.google_name,
            "bluetooth_id": mapping.bluetooth_id
        }
    return {"status": "error", "message": "Not found"}
