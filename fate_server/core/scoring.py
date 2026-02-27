def calculate_spatial_score(zone: str, time_in_zone: float) -> float:
    weights = {
        "Academic": 3.0,
        "Library": 4.0,
        "Hostel": 1.0,
        "Club": 2.0,
        "Recreation": -2.0
    }
    return time_in_zone * weights.get(zone, 0.0)

def calculate_social_score(nearby_peers: int, is_group_study: bool) -> float:
    synergy_bonus = 1.5 if is_group_study else 1.0
    # Assuming baseline multiplier grows organically with number of high-focus peers
    peer_multiplier = 1.0 + (nearby_peers * 0.1)
    
    return nearby_peers * peer_multiplier * synergy_bonus

# Dictionary for Notification Content Scoring
NOTIFICATION_URGENT_KEYWORDS = {"deadline", "meeting", "urgent", "class", "exam", "assignment", "report"}
NOTIFICATION_SOCIAL_KEYWORDS = {"liked", "post", "reel", "story", "commented", "followed", "snap"}

def calculate_digital_score(app_category: str, duration_seconds: float) -> float:
    # Baseline thresholds in seconds before penalties start applying
    category_thresholds = {
        "PRODUCTIVITY": 14400,   # 4 hours
        "EDUCATION": 10800,      # 3 hours
        "COMMUNICATION": 3600,   # 1 hour
        "ENTERTAINMENT": 1800,   # 30 mins limit for positive/neutral score
        "SOCIAL": 900,           # 15 mins
        "GAME": 1800             # 30 mins
    }
    
    threshold = category_thresholds.get(app_category.upper(), 3600)  # Default 1 hr limit
    
    # Calculate difference
    excess_usage = duration_seconds - threshold
    
    if excess_usage <= 0:
        # Staying within limits is rewarded or neutral
        return 2.0 if app_category.upper() in ["PRODUCTIVITY", "EDUCATION"] else 0.5
    else:
        # Penalize heavily for crossing thresholds (e.g. Doomscrolling)
        penalty_factor = -1.5 if app_category.upper() in ["SOCIAL", "ENTERTAINMENT", "GAME"] else -0.5
        # Penalty scales with how much they exceeded it (in minutes for math simplicity)
        return penalty_factor * (excess_usage / 60)

def calculate_notification_score(app_category: str, content: str, interaction_time: float | None) -> float:
    content_lower = content.lower()
    
    is_urgent = any(word in content_lower for word in NOTIFICATION_URGENT_KEYWORDS)
    is_social_distraction = any(word in content_lower for word in NOTIFICATION_SOCIAL_KEYWORDS)
    
    score = 0.0
    
    # Contextualizing purely by App Category first
    if app_category.upper() in ["PRODUCTIVITY", "EDUCATION"]:
        score += 1.0
    elif app_category.upper() in ["SOCIAL", "ENTERTAINMENT", "GAME"]:
        score -= 1.0
        
    # Content override
    if is_urgent:
        score += 3.0
    if is_social_distraction:
        score -= 2.0
        
    # Response Time Matrix Action
    # If interaction_time is None, it means the notification was ignored entirely
    if interaction_time is None:
        if is_social_distraction or app_category.upper() in ["SOCIAL", "ENTERTAINMENT"]:
            score += 2.0  # Big reward for ignoring distractions
        elif is_urgent:
            score -= 1.0  # Penalty for ignoring urgent things
    else:
        # Interaction happened
        if is_social_distraction or app_category.upper() in ["SOCIAL", "ENTERTAINMENT"]:
            if interaction_time < 60: # Clicked within 1 minute
                score -= 3.0 # Heavy penalty for lack of impulse control
            else:
                score -= 1.0
        elif is_urgent:
            if interaction_time < 300: # Handled within 5 minutes
                score += 2.0
                
    return score

def compute_cas(s_loc: float, s_soc: float, s_dig: float) -> float:
    alpha, beta, gamma = 0.3, 0.3, 0.4
    raw_cas = (alpha * s_loc) + (beta * s_soc) + (gamma * s_dig)
    
    # Normalize to 0-100 MVP scale
    normalized = min(max(raw_cas * 10, 0), 100)
    return normalized
