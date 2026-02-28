from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import declarative_base, relationship, sessionmaker
import datetime
import os

# Connect to Database (Use SQLite fallback for local DEV if DATABASE_URL is not set)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fate_local.db")

engine = create_engine(DATABASE_URL)
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True) # Mobile Device ID
    firebase_uid = Column(String, unique=True, nullable=True) # Optional linking
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    # Relationships
    location_logs = relationship("LocationLog", back_populates="user")
    digital_logs = relationship("DigitalLog", back_populates="user")
    proximity_logs = relationship("ProximityLog", back_populates="user")
    daily_scores = relationship("DailyScore", back_populates="user")

class LocationLog(Base):
    __tablename__ = 'location_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float) # Unix epoch
    lat = Column(Float)
    lng = Column(Float)
    mapped_zone = Column(String, nullable=True) # e.g., 'Library', 'Hostel'
    is_productive_zone = Column(Boolean, nullable=True)
    
    user = relationship("User", back_populates="location_logs")

class DigitalLog(Base):
    __tablename__ = 'digital_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    package_name = Column(String)
    duration_ms = Column(Integer)
    is_distracting = Column(Boolean, nullable=True) # Server determined
    
    user = relationship("User", back_populates="digital_logs")

class ProximityLog(Base):
    __tablename__ = 'proximity_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    nearby_peers_count = Column(Integer)
    peer_name = Column(String, nullable=True) # For debug/UI only
    
    user = relationship("User", back_populates="proximity_logs")

class DailyScore(Base):
    __tablename__ = 'daily_scores'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    date = Column(String) # YYYY-MM-DD
    cas_score = Column(Float, default=100.0) # Cumulative Attention Score
    spatial_score = Column(Float, default=100.0)
    digital_score = Column(Float, default=100.0)
    social_score = Column(Float, default=100.0)
    
    user = relationship("User", back_populates="daily_scores")

# Create tables
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
