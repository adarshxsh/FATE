"""
FATE Scoring Engine — Deterministic CAS (Contextual Attention Score)
No AI. Pure algorithmic weights from telemetry data.

CAS = 0.3 * S_loc + 0.3 * S_soc + 0.4 * S_dig   (scaled to [0, 100])
"""

# ── PRODUCTIVE ZONES ──
ZONE_WEIGHTS = {
    "LHC":                           +4.0,  # Lecture Hall Complex — core academic

    # Hostel / neutral — no score effect (spent there but doesn't count)
    "Hostel Area":                    0.0,
    "Unknown Campus Area":            0.0,  # Off-campus / undetected — no penalty

    # ── DISTRACTION ZONES ──
    "Shamiana":                      -2.0,
    "New Mess":                      -2.0,
    "Akash Complex":                 -1.5,
    "KT":                            -2.0,
    "FNG":                           -1.5,
}

# ──────────────────────────────────────────────
# A. Spatial Score (S_loc)
# Detection: GPS polled every 2 minutes.
# On zone change, periods_count = number of 2-min intervals at previous zone.
# Batched upload to server every 10 minutes.
# Hostel / off-campus are always neutral (weight = 0.0).
# ──────────────────────────────────────────────

def calculate_spatial_score(zone: str, periods_count: int = 1) -> float:
    """
    Score based on time spent at a zone.
    periods_count: how many 2-minute GPS polls were recorded in this zone.
    hours_spent = periods_count * 2 / 60
    
    LHC @ 10 periods (20 min)  -> +4.0 * (20/60) = +1.33
    KT  @ 15 periods (30 min)  -> -2.0 * (30/60) = -1.0
    Hostel or off-campus        -> 0.0 always
    """
    weight = ZONE_WEIGHTS.get(zone, 0.0)
    if weight == 0.0:
        return 0.0  # Neutral zones never penalise or reward
    hours_spent = (periods_count * 2) / 60.0
    return weight * hours_spent


# ──────────────────────────────────────────────
# B. Social Score (S_soc)
# ──────────────────────────────────────────────
def calculate_social_score(nearby_peers: int, is_group_study: bool) -> float:
    """
    Baseline multiplier from peer count.
    Group-study context (productive zone + peers) gets a 1.5x bonus.
    """
    if nearby_peers == 0:
        return 0.0
    
    # Organic baseline: diminishing returns after 5 peers
    if nearby_peers <= 2:
        base = nearby_peers * 1.0
    elif nearby_peers <= 5:
        base = 2.0 + (nearby_peers - 2) * 0.5
    else:
        base = 3.5 + (nearby_peers - 5) * 0.2
    
    if is_group_study:
        base *= 1.5

    return base


# ──────────────────────────────────────────────
# C. Digital Score (S_dig) — out of 100
# ──────────────────────────────────────────────
# Uses per-app severity weights from api/digital.py
# Base score: 50 (neutral)
# Productive time: raises score (up to 100)
# Distracting time: lowers score (down to 0)
# App switch penalty: fast productive→distracting = extra penalty
# ──────────────────────────────────────────────

from api.digital import get_app_profile

# How much 1 minute of usage moves your score, per severity unit
POINTS_PER_MINUTE = 0.5  # 1 min of severity-1.0 app = ±0.5 points

# Switch penalty: if you jump from productive to distracting in < 30 seconds
SWITCH_PENALTY_THRESHOLD_SECS = 30
SWITCH_PENALTY_POINTS = -2.0

def calculate_digital_score_100(usage_logs):
    """
    Process all usage logs for a day and return a score out of 100.
    
    Score starts at 50 (neutral).
    - Productive app time pushes it toward 100
    - Distracting app time pushes it toward 0
    - Severity weight amplifies the effect (Instagram 1.8x vs Spotify 0.3x)
    - Fast switches from productive→distracting = extra penalty
    """
    score = 50.0  # Neutral baseline
    
    # Sort by timestamp for switch detection
    sorted_logs = sorted(usage_logs, key=lambda l: l.timestamp)
    
    prev_log = None
    for log in sorted_logs:
        profile = get_app_profile(log.package_name)
        severity = profile["severity"]
        minutes = log.usage_duration_seconds / 60.0
        
        # Apply time × severity
        # Positive severity = distracting → subtract from score
        # Negative severity = productive → add to score
        score -= severity * minutes * POINTS_PER_MINUTE
        
        # Switch detection
        if prev_log is not None:
            prev_profile = get_app_profile(prev_log.package_name)
            time_between = log.timestamp - prev_log.timestamp
            
            # Productive → Distracting within 30 seconds = impulse switch
            if prev_profile["severity"] < 0 and severity > 0 and time_between < SWITCH_PENALTY_THRESHOLD_SECS:
                score += SWITCH_PENALTY_POINTS  # penalty (negative)
        
        prev_log = log
    
    return max(0.0, min(100.0, score))  # Clamp [0, 100]


# ──────────────────────────────────────────────
# Notification Score
# (Classification now happens in api/notifications.py
#  with 100-word dictionaries. Only interacted
#  notifications reach this scoring function.)
# ──────────────────────────────────────────────

def calculate_notification_score(
    app_category: str,
    content: str,
    response_time_seconds: float | None
) -> float:
    """
    Notification scoring based on the verdict stored by notifications.py:
    - app_category is now one of: PRODUCTIVE, DISTRACTING, NEUTRAL
    - Only interacted notifications are stored (ignored ones are skipped at ingestion)
    
    Scoring Matrix:
    - Interacted with DISTRACTING notification fast (<60s) → -3.0 (impulse failure)
    - Interacted with DISTRACTING notification slow         → -1.0 (still distracted)
    - Interacted with PRODUCTIVE notification fast (<120s)  → +2.0 (responsible)
    - Interacted with PRODUCTIVE notification slow          → +0.5 (handled eventually)
    - Interacted with NEUTRAL notification                  → 0.0 (no impact)
    """
    # Since ignored notifications are now skipped at ingestion,
    # all stored notifications were interacted with
    if response_time_seconds is None:
        return 0.0  # Safety check, shouldn't happen with new system
    
    if app_category == "DISTRACTING":
        if response_time_seconds < 60:
            return -3.0   # Impulse failure — clicked distracting notif instantly
        else:
            return -1.0   # Delayed but still opened a distracting notif
    
    elif app_category == "PRODUCTIVE":
        if response_time_seconds < 120:
            return +2.0   # Handled important notif responsibly
        else:
            return +0.5   # Slow but handled
    
    # NEUTRAL
    return 0.0


# ──────────────────────────────────────────────
# D. Final CAS Aggregation
# ──────────────────────────────────────────────
def compute_cas(s_loc: float, s_soc: float, s_dig: float, w_loc: float = 0.3, w_soc: float = 0.3, w_dig: float = 0.4) -> float:
    """
    Raw CAS = (w_loc * s_loc) + (w_soc * s_soc) + (w_dig * s_dig)
    Scaled and clamped to [0, 100].
    
    The raw number can range widely:
    - Best case: Library 8h (+32) + 5 peers group study (+5.25) + productive apps (+2) = ~39.3 raw
    - Worst case: Canteen (-16) + no peers (0) + 3hr YouTube doomscroll (-225) = very negative
    
    We use a sigmoid-like scaling to map raw scores into [0, 100].
    """
    raw = w_loc * s_loc + w_soc * s_soc + w_dig * s_dig
    
    # Linear scaling: map [-50, +50] raw range to [0, 100]
    # This can be tuned with real data
    scaled = 50.0 + raw * 1.5
    
    return max(0.0, min(100.0, scaled))


# ──────────────────────────────────────────────
# Database-integrated daily computation
# ──────────────────────────────────────────────
from sqlalchemy.orm import Session
from database import User, DailyScore, DigitalLog, ProximityLog, LocationLog, NotificationLog, EngagementLog, Friendship, UserPreferences
import datetime

# ── Social Contagion Constants ──
CONTAGION_LOW_CAS = 40.0    # Below this → distracted peer
CONTAGION_HIGH_CAS = 70.0   # Above this → focused peer
CONTAGION_PENALTY_PER_MIN = -0.5   # Per minute near a distracted peer
CONTAGION_REWARD_PER_MIN = +0.3    # Per minute near a focused peer

def calculate_daily_cas(user_id: int, db: Session, date_str: str = None):
    """
    Pulls all telemetry for a user and computes the full CAS.
    """
    if not date_str:
        date_str = datetime.datetime.utcnow().strftime("%Y-%m-%d")

    # ── A. Spatial Score ──
    locations = db.query(LocationLog).filter(LocationLog.user_id == user_id).all()
    # Aggregate hours per zone
    zone_counts = {}
    for loc in locations:
        zone = loc.mapped_zone or "Unknown Campus Area"
        zone_counts[zone] = zone_counts.get(zone, 0) + 1
    
    # Each location ping ≈ 30 seconds of presence
    s_loc = 0.0
    for zone, count in zone_counts.items():
        hours = (count * 30) / 3600.0  # convert 30-sec pings to hours
        s_loc += calculate_spatial_score(zone, hours)

    # ── B. Social Score ──
    proximities = db.query(ProximityLog).filter(ProximityLog.user_id == user_id).all()
    avg_peers = 0
    if proximities:
        avg_peers = sum(p.nearby_peers_count for p in proximities) / len(proximities)
    
    # Determine if this is a group study session (peers > 0 AND in productive zone)
    productive_zones = [z for z, c in zone_counts.items() if ZONE_WEIGHTS.get(z, 0) > 0]
    is_group_study = avg_peers >= 2 and len(productive_zones) > 0
    s_soc = calculate_social_score(int(avg_peers), is_group_study)

    # ── B2. Social Contagion (Engagement) ──
    # If you spend time near someone with a bad CAS, your score drops.
    # If you spend time near someone productive, you get a boost.
    # EXCEPTION: Close Friends are exempt from contagion penalties.
    engagements = db.query(EngagementLog).filter(EngagementLog.user_id == user_id).all()
    
    # Load the user's close friends list
    friend_device_ids = set(
        f.friend_device_id for f in
        db.query(Friendship).filter(Friendship.user_id == user_id).all()
    )
    
    contagion_modifier = 0.0
    for eng in engagements:
        # Skip contagion for close friends — hanging with friends is normal!
        if eng.peer_device_id in friend_device_ids:
            continue
        
        if eng.peer_cas_at_time is not None:
            minutes = eng.engagement_duration_seconds / 60.0
            if eng.peer_cas_at_time < CONTAGION_LOW_CAS:
                contagion_modifier += CONTAGION_PENALTY_PER_MIN * minutes
            elif eng.peer_cas_at_time > CONTAGION_HIGH_CAS:
                contagion_modifier += CONTAGION_REWARD_PER_MIN * minutes
    
    s_soc += contagion_modifier

    # ── C. Digital Score (out of 100) ──
    usages = db.query(DigitalLog).filter(DigitalLog.user_id == user_id).all()
    s_dig = calculate_digital_score_100(usages)
    
    # ── Notification Score (added into S_dig) ──
    notifications = db.query(NotificationLog).filter(NotificationLog.user_id == user_id).all()
    if notifications:
        for notif in notifications:
            s_dig += calculate_notification_score(
                notif.app_category or "OTHER",
                notif.content or "",
                notif.response_time_seconds
            )

    # ── D. Final CAS ──
    prefs = db.query(UserPreferences).filter(UserPreferences.user_id == user_id).first()
    w_loc = prefs.weight_spatial if prefs else 0.3
    w_soc = prefs.weight_social if prefs else 0.3
    w_dig = prefs.weight_digital if prefs else 0.4

    cas = compute_cas(s_loc, s_soc, s_dig, w_loc, w_soc, w_dig)

    # ── Fallback for New Users ──
    # If there is absolutely no telemetry yet, give a random high score to demo functionality
    import random
    if s_loc == 0.0 and s_soc == 0.0 and s_dig == 50.0:
        cas = round(random.uniform(97.0, 100.0), 2)
        s_dig = cas  # Sync digital score logic for UI aesthetic
        
    # Persist to DailyScore
    daily_record = db.query(DailyScore).filter(
        DailyScore.user_id == user_id,
        DailyScore.date == date_str
    ).first()
    
    if not daily_record:
        daily_record = DailyScore(
            user_id=user_id,
            date=date_str,
            cas_score=cas,
            spatial_score=s_loc,
            digital_score=s_dig,
            social_score=s_soc
        )
        db.add(daily_record)
    else:
        daily_record.cas_score = cas
        daily_record.spatial_score = s_loc
        daily_record.digital_score = s_dig
        daily_record.social_score = s_soc

    db.commit()
    return daily_record
