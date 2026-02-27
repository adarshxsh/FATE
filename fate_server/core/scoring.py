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

def calculate_digital_score(app: str, duration: float, notif_severity: float) -> float:
    app_weights = {
        "Notion": 3.0,
        "Docs": 3.0,
        "YouTube": -2.0,
        "Instagram": -4.0,
        "WhatsApp": -1.0
    }
    
    app_score = duration * app_weights.get(app, -1.0)
    return app_score - notif_severity

def compute_cas(s_loc: float, s_soc: float, s_dig: float) -> float:
    alpha, beta, gamma = 0.3, 0.3, 0.4
    raw_cas = (alpha * s_loc) + (beta * s_soc) + (gamma * s_dig)
    
    # Normalize to 0-100 MVP scale
    normalized = min(max(raw_cas * 10, 0), 100)
    return normalized
