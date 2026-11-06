from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import declarative_base, relationship, sessionmaker
import datetime
import os

# Connect to Database (Use SQLite fallback for local DEV if DATABASE_URL is not set)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fate_local.db")
# SQLAlchemy 2.x rejects the legacy "postgres://" scheme some hosts still hand out.
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # pool_pre_ping: managed Postgres drops idle connections; without it the
    # first request after a quiet period fails with "server closed the connection".
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True)
    firebase_uid = Column(String, unique=True, nullable=True)
    username = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    location_logs = relationship("LocationLog", back_populates="user")
    digital_logs = relationship("DigitalLog", back_populates="user")
    proximity_logs = relationship("ProximityLog", back_populates="user")
    notification_logs = relationship("NotificationLog", back_populates="user")
    engagement_logs = relationship("EngagementLog", back_populates="user")
    friendships = relationship("Friendship", back_populates="user")
    daily_scores = relationship("DailyScore", back_populates="user")
    preferences = relationship("UserPreferences", back_populates="user", uselist=False)
    device_mapping = relationship("DeviceMapping", back_populates="user", uselist=False)

class DeviceMapping(Base):
    __tablename__ = 'device_mappings'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True)
    google_name = Column(String)
    bluetooth_id = Column(String, unique=True, index=True)
    
    user = relationship("User", back_populates="device_mapping")

class UserPreferences(Base):
    __tablename__ = 'user_preferences'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True)
    weight_spatial = Column(Float, default=0.3)
    weight_social = Column(Float, default=0.3)
    weight_digital = Column(Float, default=0.4)
    
    user = relationship("User", back_populates="preferences")

class Friendship(Base):
    """Close friends bypass the Social Contagion penalty."""
    __tablename__ = 'friendships'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    friend_device_id = Column(String, index=True)  # The friend's device_id
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="friendships")

class LocationLog(Base):
    __tablename__ = 'location_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    lat = Column(Float)
    lng = Column(Float)
    mapped_zone = Column(String, nullable=True)
    is_productive_zone = Column(Boolean, nullable=True)
    
    user = relationship("User", back_populates="location_logs")

class DigitalLog(Base):
    __tablename__ = 'digital_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    package_name = Column(String)
    app_category = Column(String, nullable=True)  # PRODUCTIVITY, ENTERTAINMENT, SOCIAL, EDUCATION, GAME
    duration_ms = Column(Integer)
    usage_duration_seconds = Column(Float, nullable=True)
    is_distracting = Column(Boolean, nullable=True)
    
    user = relationship("User", back_populates="digital_logs")

class ProximityLog(Base):
    __tablename__ = 'proximity_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    nearby_peers_count = Column(Integer)
    peer_name = Column(String, nullable=True)
    distance = Column(Float, nullable=True)
    
    user = relationship("User", back_populates="proximity_logs")

class NotificationLog(Base):
    __tablename__ = 'notification_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    timestamp = Column(Float)
    app_category = Column(String)  # SOCIAL, PRODUCTIVITY, URGENT, etc.
    content = Column(String, nullable=True)
    response_time_seconds = Column(Float, nullable=True)  # None = ignored/dismissed
    
    user = relationship("User", back_populates="notification_logs")

class EngagementLog(Base):
    """Tracks prolonged proximity engagement between two FATE users."""
    __tablename__ = 'engagement_logs'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))          # The reporting user
    peer_device_id = Column(String)                             # The other device's ID
    timestamp = Column(Float)
    engagement_duration_seconds = Column(Float)                 # How long they've been near each other
    peer_cas_at_time = Column(Float, nullable=True)             # Snapshot of peer's CAS when logged
    
    user = relationship("User", back_populates="engagement_logs")

class DailyScore(Base):
    __tablename__ = 'daily_scores'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    date = Column(String)
    cas_score = Column(Float, default=0.0)
    spatial_score = Column(Float, default=0.0)
    digital_score = Column(Float, default=0.0)
    social_score = Column(Float, default=0.0)
    
    user = relationship("User", back_populates="daily_scores")

# ── Community layer (v2) ─────────────────────────────────
# The v2 app keeps raw telemetry encrypted on the phone. The server only
# holds what needs more than one device to compute: each member's score
# history, who-was-near-whom engagement edges, and campus aggregates.

class CommunityDevice(Base):
    __tablename__ = 'community_devices'
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(String, unique=True, index=True, nullable=False)      # app UUID, never broadcast
    bluetooth_id = Column(String, unique=True, index=True, nullable=False)  # broadcast over Nearby
    display_name = Column(String, nullable=True)
    token_hash = Column(String, unique=True, index=True, nullable=False)    # sha256 of bearer token
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    last_seen = Column(Float, nullable=True)


class ScoreSnapshot(Base):
    __tablename__ = 'score_snapshots'
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(Integer, ForeignKey('community_devices.id', ondelete='CASCADE'), index=True)
    timestamp = Column(Float, index=True)
    cas = Column(Float)
    s_loc = Column(Float)
    s_soc = Column(Float)
    s_dig = Column(Float)
    zone = Column(String, nullable=True)  # only sent when the user opts in


class CommunityEngagement(Base):
    __tablename__ = 'community_engagements'
    id = Column(Integer, primary_key=True, index=True)
    reporter_id = Column(Integer, ForeignKey('community_devices.id', ondelete='CASCADE'), index=True)
    peer_id = Column(Integer, ForeignKey('community_devices.id', ondelete='SET NULL'), nullable=True, index=True)
    peer_bluetooth_id = Column(String, index=True)
    ended_at = Column(Float, index=True)
    duration_seconds = Column(Float)
    peer_cas = Column(Float, nullable=True)  # peer's CAS at ended_at; NULL if peer unknown/stale


# Create tables
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
