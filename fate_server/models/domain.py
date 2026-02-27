from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.sql import func
from core.database import Base
import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    mac_address = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class LocationLog(Base):
    __tablename__ = "location_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_email = Column(String, index=True)
    timestamp = Column(Float, index=True)
    lat = Column(Float)
    lng = Column(Float)
    
class ProximityLog(Base):
    __tablename__ = "proximity_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_email = Column(String, index=True)
    timestamp = Column(Float, index=True)
    nearby_peers = Column(Integer)
    
class DigitalLog(Base):
    __tablename__ = "digital_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_email = Column(String, index=True)
    timestamp = Column(Float, index=True)
    app_category = Column(String)
    usage_duration_seconds = Column(Float)
    
class NotificationLog(Base):
    __tablename__ = "notification_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_email = Column(String, index=True)
    timestamp = Column(Float, index=True)
    app_category = Column(String)
    content = Column(String)
    response_time_seconds = Column(Float, nullable=True)

class CASHistory(Base):
    __tablename__ = "cas_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_email = Column(String, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    s_loc = Column(Float)
    s_soc = Column(Float)
    s_dig = Column(Float)
    cas_score = Column(Float)    
