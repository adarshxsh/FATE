from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

class AuthRequest(BaseModel):
    google_id_token: str
    device_mac: str

class AuthResponse(BaseModel):
    jwt_token: str
    user_email: str

@router.post("/verify")
async def authenticate_user(req: AuthRequest):
    # MVP Mock: Assuming the token itself is the email for demonstration purposes
    email = req.google_id_token
    
    if not email.endswith("@iitj.ac.in"):
        raise HTTPException(status_code=403, detail="Only @iitj.ac.in accounts are permitted to join FATE.")
        
    return AuthResponse(
        jwt_token=f"mock_jwt_for_{email}",
        user_email=email
    )
