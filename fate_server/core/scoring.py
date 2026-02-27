from sqlalchemy.orm import Session
from database import User, DailyScore, DigitalLog, ProximityLog, LocationLog
import datetime

def calculate_daily_cas(user_id: int, db: Session, date_str: str = None):
    """
    Core Algorithmic Scoring Engine to compute Cumulative Attention Score (CAS).
    No AI, purely mathematical weights based on telemetry.
    """
    if not date_str:
        date_str = datetime.datetime.utcnow().strftime("%Y-%m-%d")

    # Base Scores
    cas_score = 100.0
    spatial_score = 100.0
    social_score = 100.0
    digital_score = 100.0

    # 1. Spatial Score Calculation (Location)
    locations = db.query(LocationLog).filter(
        LocationLog.user_id == user_id, 
        # Ideally filter by timestamp today, skipped for MVP simplicity
    ).all()
    
    productive_time = 0
    distractive_time = 0
    for loc in locations:
        if loc.is_productive_zone:
            productive_time += 1
        else:
            distractive_time += 1
            
    if (productive_time + distractive_time) > 0:
        spatial_penalty = (distractive_time / (productive_time + distractive_time)) * 20
        spatial_score -= spatial_penalty

    # 2. Digital Score Calculation (App Usage & Distractions)
    usages = db.query(DigitalLog).filter(DigitalLog.user_id == user_id).all()
    distraction_minutes = 0
    
    for use in usages:
        if use.is_distracting:
            distraction_minutes += (use.duration_ms / 60000) # Convert ms to mins
            
    # Penalty: Lose 2 points for every minute spent on a distracting app
    digital_score -= (distraction_minutes * 2.0)
    digital_score = max(0.0, digital_score)

    # 3. Social Synergy Score Calculation (Proximity)
    proximities = db.query(ProximityLog).filter(ProximityLog.user_id == user_id).all()
    total_peers = sum(p.nearby_peers_count for p in proximities)
    
    # Simple algorithmic rule: Too much continuous proximity might mean socializing instead of studying
    if total_peers > 50: # Adjust threshold based on real data
        social_score -= 15.0

    # 4. Final CAS Calculation (Weighted Average)
    # Weights: Digital habits are most important (50%), where you are (30%), who you are with (20%)
    cas_score = (digital_score * 0.5) + (spatial_score * 0.3) + (social_score * 0.2)
    
    # Store or Update in DB
    daily_record = db.query(DailyScore).filter(
        DailyScore.user_id == user_id,
        DailyScore.date == date_str
    ).first()
    
    if not daily_record:
        daily_record = DailyScore(
            user_id=user_id,
            date=date_str,
            cas_score=cas_score,
            spatial_score=spatial_score,
            digital_score=digital_score,
            social_score=social_score
        )
        db.add(daily_record)
    else:
        daily_record.cas_score = cas_score
        daily_record.spatial_score = spatial_score
        daily_record.digital_score = digital_score
        daily_record.social_score = social_score

    db.commit()
    return daily_record
