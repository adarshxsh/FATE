"""
Notification Scoring System.

Rules:
1. Score out of 100 based on interaction with good/bad notifications
2. If user ignores → system ignores too (response_time = None → skip scoring)
3. Categorize by app first, then override by content keywords
4. 100-word content dictionaries per category
5. YouTube/dual-nature apps can be good or bad depending on content
6. Unknown apps → use play_store_category field
7. Server batches notification data every 5 min from Flutter
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db, NotificationLog, User

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

# ═══════════════════════════════════════════════════════════
# APP → BASE CATEGORY MAPPING (popular apps)
# ═══════════════════════════════════════════════════════════
APP_CATEGORY_MAP = {
    # Social / Distracting
    "com.instagram.android": "SOCIAL",
    "com.snapchat.android": "SOCIAL",
    "com.facebook.katana": "SOCIAL",
    "com.twitter.android": "SOCIAL",
    "com.zhiliaoapp.musically": "SOCIAL",  # TikTok
    "com.pinterest": "SOCIAL",
    "com.reddit.frontpage": "SOCIAL",
    "com.tumblr": "SOCIAL",
    # Messaging (can be productive or social)
    "com.whatsapp": "MESSAGING",
    "org.telegram.messenger": "MESSAGING",
    "com.facebook.orca": "MESSAGING",
    "com.discord": "MESSAGING",
    "com.skype.raider": "MESSAGING",
    "com.viber.voip": "MESSAGING",
    "com.google.android.apps.messaging": "MESSAGING",
    # Dual-nature — can be productive or distracting
    "com.google.android.youtube": "DUAL",
    "com.spotify.music": "DUAL",
    "com.netflix.mediaclient": "ENTERTAINMENT",
    "com.amazon.avod.thirdpartyclient": "ENTERTAINMENT",
    # Productivity
    "com.google.android.gm": "PRODUCTIVITY",
    "com.microsoft.office.outlook": "PRODUCTIVITY",
    "com.google.android.apps.docs": "PRODUCTIVITY",
    "com.google.android.apps.docs.editors.docs": "PRODUCTIVITY",
    "com.google.android.apps.docs.editors.sheets": "PRODUCTIVITY",
    "com.notion.id": "PRODUCTIVITY",
    "com.todoist": "PRODUCTIVITY",
    "com.slack": "PRODUCTIVITY",
    "com.microsoft.teams": "PRODUCTIVITY",
    "com.asana.app": "PRODUCTIVITY",
    "com.trello": "PRODUCTIVITY",
    # Education
    "com.google.android.apps.classroom": "EDUCATION",
    "com.duolingo": "EDUCATION",
    "com.coursera.app": "EDUCATION",
    "com.udemy.android": "EDUCATION",
    "org.khanacademy.android": "EDUCATION",
    "com.byju": "EDUCATION",
    "com.unacademy.unacademyapp": "EDUCATION",
    # Urgent / System
    "com.google.android.calendar": "URGENT",
    "com.google.android.dialer": "URGENT",
    "com.android.phone": "URGENT",
    "com.truecaller": "URGENT",
    # Games
    "com.supercell.clashofclans": "GAME",
    "com.kiloo.subwaysurf": "GAME",
    "com.pubg.krmobile": "GAME",
    "com.epicgames.fortnite": "GAME",
    "com.mojang.minecraftpe": "GAME",
    # Shopping / Entertainment
    "com.amazon.mShop.android.shopping": "SHOPPING",
    "com.flipkart.android": "SHOPPING",
    "in.swiggy.android": "FOOD",
    "com.application.zomato": "FOOD",
}

# ═══════════════════════════════════════════════════════════
# CONTENT KEYWORD DICTIONARIES (~100 words each)
# ═══════════════════════════════════════════════════════════

# Keywords that indicate PRODUCTIVE / URGENT / GOOD notifications
PRODUCTIVE_KEYWORDS = [
    # Academic / Work
    "deadline", "assignment", "submission", "exam", "quiz", "test", "grade",
    "lecture", "seminar", "workshop", "presentation", "project", "report",
    "research", "thesis", "dissertation", "homework", "syllabus", "attendance",
    "schedule", "timetable", "marks", "result", "gpa", "cgpa", "professor",
    # Work / Professional
    "meeting", "standup", "sprint", "deploy", "review", "merge", "commit",
    "production", "release", "milestone", "update", "agenda", "minutes",
    "proposal", "invoice", "contract", "salary", "payroll", "appraisal",
    "interview", "opportunity", "application", "internship", "placement",
    # Urgent / Important
    "urgent", "important", "critical", "asap", "immediately", "reminder",
    "due", "overdue", "pending", "action", "required", "mandatory",
    "confirm", "verification", "otp", "password", "security", "alert",
    "warning", "emergency", "safety", "health", "medical", "appointment",
    # Productivity Apps
    "task", "todo", "complete", "progress", "milestone", "goal", "target",
    "focus", "productivity", "workflow", "collaborate", "shared", "document",
    "spreadsheet", "calendar", "event", "schedule", "plan", "organize",
    # Education
    "course", "lesson", "chapter", "tutorial", "certification", "learning",
    "study", "practice", "exercise", "solution", "answer", "doubt",
]

# Keywords that indicate DISTRACTING / BAD notifications
DISTRACTING_KEYWORDS = [
    # Social Media
    "liked", "likes", "reel", "reels", "story", "stories", "tagged",
    "commented", "comment", "followed", "follower", "following", "mention",
    "mentioned", "shared", "reshared", "repost", "retweet", "retweeted",
    "trending", "viral", "explore", "discover", "suggested", "recommend",
    # Entertainment / Gossip
    "streak", "snap", "snapstreak", "flame", "meme", "memes", "funny",
    "lol", "lmao", "rofl", "haha", "😂", "🤣", "gossip", "drama",
    "celebrity", "dating", "crush", "match", "swipe", "tinder", "bumble",
    "challenge", "dare", "prank", "reaction", "subscribe", "unboxing",
    # Gaming
    "play", "game", "match", "battle", "raid", "clan", "trophy",
    "league", "rank", "season", "loot", "chest", "reward", "coins",
    "gems", "lives", "energy", "attack", "defend", "level", "upgrade",
    # Shopping / Sales
    "sale", "discount", "offer", "deal", "coupon", "cashback", "flash",
    "limited", "exclusive", "buy", "shop", "cart", "wishlist", "price",
    "order", "delivery", "shipped", "arriving", "tracking",
    # Clickbait
    "shocking", "unbelievable", "amazing", "incredible", "insane", "crazy",
    "must", "watch", "click", "check", "see", "look", "omg", "wow",
    "breaking", "exclusive", "secret", "revealed", "exposed",
]

# Keywords for NEUTRAL (dual-nature) — scored as 0
NEUTRAL_KEYWORDS = [
    "update", "available", "new", "version", "feature", "download",
    "install", "backup", "sync", "storage", "battery", "wifi", "data",
    "settings", "permission", "privacy", "terms", "policy", "feedback",
    "rate", "review", "survey", "beta", "changelog",
]


def classify_notification(package: str, content: str, play_store_category: str = None):
    """
    Two-pass classification:
    1. App-level category (from hardcoded map or play_store_category)
    2. Content-level override (keyword scan overrides app category)
    
    Returns: ("PRODUCTIVE", "DISTRACTING", or "NEUTRAL") + confidence score
    """
    # Pass 1: App-level base category
    base_category = APP_CATEGORY_MAP.get(package)
    if not base_category and play_store_category:
        # Fallback to Play Store category
        psc = play_store_category.upper()
        if psc in ("EDUCATION", "BOOKS_AND_REFERENCE"):
            base_category = "EDUCATION"
        elif psc in ("PRODUCTIVITY", "BUSINESS", "FINANCE"):
            base_category = "PRODUCTIVITY"
        elif psc in ("SOCIAL", "COMMUNICATION"):
            base_category = "SOCIAL"
        elif psc in ("GAME", "GAME_ACTION", "GAME_CASUAL", "GAME_PUZZLE"):
            base_category = "GAME"
        elif psc in ("ENTERTAINMENT", "MUSIC_AND_AUDIO", "VIDEO_PLAYERS"):
            base_category = "ENTERTAINMENT"
        elif psc in ("SHOPPING", "FOOD_AND_DRINK"):
            base_category = "SHOPPING"
        else:
            base_category = "OTHER"
    
    if not base_category:
        base_category = "OTHER"

    # Pass 2: Content keyword scan
    content_lower = (content or "").lower()
    
    productive_hits = sum(1 for kw in PRODUCTIVE_KEYWORDS if kw in content_lower)
    distracting_hits = sum(1 for kw in DISTRACTING_KEYWORDS if kw in content_lower)
    
    # Content override logic
    if productive_hits > distracting_hits and productive_hits >= 1:
        verdict = "PRODUCTIVE"
    elif distracting_hits > productive_hits and distracting_hits >= 1:
        verdict = "DISTRACTING"
    else:
        # No clear content signal → fall back to app category
        if base_category in ("SOCIAL", "GAME", "ENTERTAINMENT", "SHOPPING", "FOOD"):
            verdict = "DISTRACTING"
        elif base_category in ("PRODUCTIVITY", "EDUCATION", "URGENT"):
            verdict = "PRODUCTIVE"
        elif base_category == "DUAL":
            verdict = "NEUTRAL"
        elif base_category == "MESSAGING":
            verdict = "NEUTRAL"  # messaging is ambiguous without content
        else:
            verdict = "NEUTRAL"
    
    return verdict, base_category, productive_hits, distracting_hits


# ═══════════════════════════════════════════════════════════
# PYDANTIC MODEL
# ═══════════════════════════════════════════════════════════

class NotificationData(BaseModel):
    user_id: int
    timestamp: float
    package: str
    content: str
    response_time_seconds: float | None = None  # None = ignored/dismissed
    play_store_category: str | None = None  # For unknown apps


# ═══════════════════════════════════════════════════════════
# ENDPOINT
# ═══════════════════════════════════════════════════════════

@router.post("/notification")
def ingest_notification(data: NotificationData, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == data.user_id).first()
    if not user:
        return {"status": "error", "message": "User not found"}

    # Rule: If user ignored the notification → we ignore it too
    if data.response_time_seconds is None:
        return {
            "status": "ignored",
            "reason": "User did not interact — notification skipped"
        }

    # Classify the notification
    verdict, app_cat, prod_hits, dist_hits = classify_notification(
        data.package, data.content, data.play_store_category
    )

    # Store with the verdict as app_category
    log = NotificationLog(
        user_id=data.user_id,
        timestamp=data.timestamp,
        app_category=verdict,  # PRODUCTIVE, DISTRACTING, or NEUTRAL
        content=data.content,
        response_time_seconds=data.response_time_seconds
    )
    
    db.add(log)
    db.commit()
    
    return {
        "status": "success",
        "verdict": verdict,
        "app_base_category": app_cat,
        "productive_keyword_hits": prod_hits,
        "distracting_keyword_hits": dist_hits,
        "response_time": data.response_time_seconds,
    }
