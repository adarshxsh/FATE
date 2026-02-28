from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, Friendship, User

router = APIRouter(prefix="/api/friends", tags=["friends"])

class AddFriendRequest(BaseModel):
    user_id: int
    friend_device_id: str

class RemoveFriendRequest(BaseModel):
    user_id: int
    friend_device_id: str

@router.post("/add")
def add_friend(data: AddFriendRequest, db: Session = Depends(get_db)):
    """
    Handshake: Add a nearby peer as a close friend.
    Friends bypass the Social Contagion penalty entirely.
    """
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    # Check if already friends
    existing = db.query(Friendship).filter(
        Friendship.user_id == data.user_id,
        Friendship.friend_device_id == data.friend_device_id
    ).first()
    
    if existing:
        return {"status": "already_friends", "message": "Already in your close friends list"}

    friendship = Friendship(
        user_id=data.user_id,
        friend_device_id=data.friend_device_id
    )
    db.add(friendship)
    db.commit()

    return {"status": "success", "message": f"Added {data.friend_device_id} as close friend"}

@router.post("/remove")
def remove_friend(data: RemoveFriendRequest, db: Session = Depends(get_db)):
    """Remove a peer from close friends list."""
    friendship = db.query(Friendship).filter(
        Friendship.user_id == data.user_id,
        Friendship.friend_device_id == data.friend_device_id
    ).first()
    
    if not friendship:
        return {"status": "not_found", "message": "Friendship not found"}
    
    db.delete(friendship)
    db.commit()
    return {"status": "success", "message": "Friend removed"}

@router.get("/list/{user_id}")
def list_friends(user_id: int, db: Session = Depends(get_db)):
    """Get all close friends for a user."""
    friendships = db.query(Friendship).filter(Friendship.user_id == user_id).all()
    return {
        "status": "success",
        "friends": [f.friend_device_id for f in friendships]
    }
