"""
App Usage Scoring System.

Rules:
1. Score out of 100 based on time on productive vs distracting apps
2. Different apps have different severity weights (Instagram > YouTube > WhatsApp)
3. Unknown apps → Play Store category fallback
4. App switching penalty: productive → distracting within < 30s = impulse penalty
5. Updated every 5 min on device + server
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, DigitalLog, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

# ═══════════════════════════════════════════════════════════
# APP → CATEGORY + SEVERITY WEIGHT
# severity: multiplier on time penalty (higher = worse)
# ═══════════════════════════════════════════════════════════
APP_PROFILES = {
    # ── SOCIAL (distraction severity varies) ──
    "com.instagram.android":        {"cat": "SOCIAL",        "severity": 1.8},  # Doom-scroll king
    "com.zhiliaoapp.musically":     {"cat": "SOCIAL",        "severity": 1.8},  # TikTok
    "com.snapchat.android":         {"cat": "SOCIAL",        "severity": 1.5},
    "com.facebook.katana":          {"cat": "SOCIAL",        "severity": 1.4},
    "com.twitter.android":          {"cat": "SOCIAL",        "severity": 1.3},
    "com.reddit.frontpage":         {"cat": "SOCIAL",        "severity": 1.3},
    "com.pinterest":                {"cat": "SOCIAL",        "severity": 1.0},
    "com.tumblr":                   {"cat": "SOCIAL",        "severity": 1.0},
    
    # ── MESSAGING (low severity, can be productive) ──
    "com.whatsapp":                 {"cat": "MESSAGING",     "severity": 0.5},
    "org.telegram.messenger":       {"cat": "MESSAGING",     "severity": 0.4},
    "com.facebook.orca":            {"cat": "MESSAGING",     "severity": 0.6},
    "com.discord":                  {"cat": "MESSAGING",     "severity": 0.5},
    "com.skype.raider":             {"cat": "MESSAGING",     "severity": 0.3},
    "com.google.android.apps.messaging": {"cat": "MESSAGING", "severity": 0.2},
    
    # ── ENTERTAINMENT ──
    "com.google.android.youtube":   {"cat": "ENTERTAINMENT", "severity": 1.2},  # Can be educational
    "com.spotify.music":            {"cat": "ENTERTAINMENT", "severity": 0.3},  # Background music OK
    "com.netflix.mediaclient":      {"cat": "ENTERTAINMENT", "severity": 1.5},
    "com.amazon.avod.thirdpartyclient": {"cat": "ENTERTAINMENT", "severity": 1.5},
    
    # ── GAMES ──
    "com.supercell.clashofclans":   {"cat": "GAME",          "severity": 2.0},
    "com.kiloo.subwaysurf":         {"cat": "GAME",          "severity": 2.0},
    "com.pubg.krmobile":            {"cat": "GAME",          "severity": 2.0},
    "com.epicgames.fortnite":       {"cat": "GAME",          "severity": 2.0},
    "com.mojang.minecraftpe":       {"cat": "GAME",          "severity": 1.5},
    
    # ── PRODUCTIVITY (positive severity = reward multiplier) ──
    "com.google.android.apps.docs": {"cat": "PRODUCTIVITY",  "severity": -1.0},
    "com.google.android.apps.docs.editors.docs":  {"cat": "PRODUCTIVITY", "severity": -1.0},
    "com.google.android.apps.docs.editors.sheets": {"cat": "PRODUCTIVITY", "severity": -1.0},
    "com.google.android.apps.docs.editors.slides": {"cat": "PRODUCTIVITY", "severity": -1.0},
    "com.microsoft.office.word":    {"cat": "PRODUCTIVITY",  "severity": -1.0},
    "com.microsoft.office.excel":   {"cat": "PRODUCTIVITY",  "severity": -1.0},
    "com.notion.id":                {"cat": "PRODUCTIVITY",  "severity": -1.2},
    "com.todoist":                  {"cat": "PRODUCTIVITY",  "severity": -0.8},
    "com.slack":                    {"cat": "PRODUCTIVITY",  "severity": -0.5},
    "com.microsoft.teams":          {"cat": "PRODUCTIVITY",  "severity": -0.5},
    "com.google.android.gm":        {"cat": "PRODUCTIVITY",  "severity": -0.3},
    "com.microsoft.office.outlook": {"cat": "PRODUCTIVITY",  "severity": -0.3},
    
    # ── EDUCATION ──
    "com.google.android.apps.classroom": {"cat": "EDUCATION", "severity": -1.5},
    "com.duolingo":                 {"cat": "EDUCATION",     "severity": -1.0},
    "com.coursera.app":             {"cat": "EDUCATION",     "severity": -1.2},
    "com.udemy.android":            {"cat": "EDUCATION",     "severity": -1.2},
    "org.khanacademy.android":      {"cat": "EDUCATION",     "severity": -1.2},
    "com.byju":                     {"cat": "EDUCATION",     "severity": -1.0},
    "com.unacademy.unacademyapp":   {"cat": "EDUCATION",     "severity": -1.0},
    
    # ── SHOPPING ──
    "com.amazon.mShop.android.shopping": {"cat": "SHOPPING", "severity": 1.0},
    "com.flipkart.android":         {"cat": "SHOPPING",      "severity": 1.0},
    
    # ── FOOD ──
    "in.swiggy.android":            {"cat": "FOOD",          "severity": 0.5},
    "com.application.zomato":       {"cat": "FOOD",          "severity": 0.5},
    
    # ── SYSTEM (neutral) ──
    "com.android.settings":         {"cat": "SYSTEM",        "severity": 0.0},
    "com.sec.android.app.launcher": {"cat": "SYSTEM",        "severity": 0.0},
    "com.android.vending":          {"cat": "SYSTEM",        "severity": 0.0},  # Play Store
}

# Play Store category → default severity for unknown apps
PLAY_STORE_DEFAULTS = {
    "EDUCATION": {"cat": "EDUCATION", "severity": -1.0},
    "BOOKS_AND_REFERENCE": {"cat": "EDUCATION", "severity": -0.8},
    "PRODUCTIVITY": {"cat": "PRODUCTIVITY", "severity": -0.5},
    "BUSINESS": {"cat": "PRODUCTIVITY", "severity": -0.5},
    "FINANCE": {"cat": "PRODUCTIVITY", "severity": -0.3},
    "SOCIAL": {"cat": "SOCIAL", "severity": 1.0},
    "COMMUNICATION": {"cat": "MESSAGING", "severity": 0.4},
    "ENTERTAINMENT": {"cat": "ENTERTAINMENT", "severity": 1.2},
    "MUSIC_AND_AUDIO": {"cat": "ENTERTAINMENT", "severity": 0.3},
    "VIDEO_PLAYERS": {"cat": "ENTERTAINMENT", "severity": 1.2},
    "GAME": {"cat": "GAME", "severity": 2.0},
    "GAME_ACTION": {"cat": "GAME", "severity": 2.0},
    "GAME_CASUAL": {"cat": "GAME", "severity": 1.5},
    "GAME_PUZZLE": {"cat": "GAME", "severity": 1.5},
    "SHOPPING": {"cat": "SHOPPING", "severity": 1.0},
    "FOOD_AND_DRINK": {"cat": "FOOD", "severity": 0.5},
    "HEALTH_AND_FITNESS": {"cat": "PRODUCTIVITY", "severity": -0.3},
    "MAPS_AND_NAVIGATION": {"cat": "SYSTEM", "severity": 0.0},
    "TOOLS": {"cat": "SYSTEM", "severity": 0.0},
}


def get_app_profile(package: str, play_store_category: str = None):
    """Get category and severity for an app."""
    profile = APP_PROFILES.get(package)
    if profile:
        return profile
    
    # Fallback to Play Store category
    if play_store_category:
        default = PLAY_STORE_DEFAULTS.get(play_store_category.upper())
        if default:
            return default
    
    return {"cat": "OTHER", "severity": 0.0}


class DigitalData(BaseModel):
    user_id: int
    timestamp: float
    package: str
    duration: int   # duration in ms from Flutter
    play_store_category: str | None = None
    # App switch tracking (sent by Flutter)
    prev_package: str | None = None
    switch_time_seconds: float | None = None  # Time between switches


@router.post("/digital")
def ingest_digital(data: DigitalData, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    profile = get_app_profile(data.package, data.play_store_category)
    app_category = profile["cat"]
    severity = profile["severity"]
    usage_seconds = data.duration / 1000.0
    is_distracting = severity > 0

    # App switch penalty detection
    switch_penalty = 0.0
    if data.prev_package and data.switch_time_seconds is not None:
        prev_profile = get_app_profile(data.prev_package)
        prev_severity = prev_profile["severity"]
        
        # Productive → Distracting switch within 30 seconds = impulse penalty
        if prev_severity < 0 and severity > 0 and data.switch_time_seconds < 30:
            switch_penalty = -2.0 * severity  # Scaled by how distracting the new app is
    
    log = DigitalLog(
        user_id=data.user_id,
        timestamp=data.timestamp,
        package_name=data.package,
        app_category=app_category,
        duration_ms=data.duration,
        usage_duration_seconds=usage_seconds,
        is_distracting=is_distracting
    )
    
    db.add(log)
    db.commit()
    
    return {
        "status": "success",
        "app_category": app_category,
        "severity": severity,
        "is_distracting": is_distracting,
        "switch_penalty": switch_penalty,
    }
