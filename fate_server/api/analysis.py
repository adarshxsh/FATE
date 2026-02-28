"""
Database Garbage Collector & Analysis Scheduler.
- Cleans raw telemetry logs older than 24h (after aggregation into DailyScore)
- Provides analysis snapshot + server-pushed insight notifications
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import datetime

from database import (
    get_db,
    LocationLog, DigitalLog, ProximityLog, NotificationLog, EngagementLog,
    DailyScore
)
from core import scoring

router = APIRouter(prefix="/api", tags=["analysis"])


# ═══════════════════════════════════════════════════════════
# Insight Generator
# Produces human-readable notifications based on CAS data
# ═══════════════════════════════════════════════════════════

def generate_insights(cas, s_loc, s_soc, s_dig, prev_cas=None):
    """
    Produce a list of insight notifications based on current scores.
    Each insight: {type: info/warning/success, title, body, icon}
    """
    insights = []
    
    # ── Overall CAS Level ──
    if cas >= 80:
        insights.append({
            "type": "success",
            "title": "🔥 Deep Focus Mode",
            "body": f"Your CAS is {cas}. You're in the zone — keep it up!",
            "icon": "trending_up",
        })
    elif cas >= 60:
        insights.append({
            "type": "info",
            "title": "⚡ Moderate Focus",
            "body": f"CAS at {cas}. Solid productivity. Small improvements possible.",
            "icon": "speed",
        })
    elif cas >= 40:
        insights.append({
            "type": "warning",
            "title": "⚠️ Attention Drifting",
            "body": f"CAS dropped to {cas}. Consider reducing phone usage.",
            "icon": "warning",
        })
    else:
        insights.append({
            "type": "warning",
            "title": "🚨 High Distraction",
            "body": f"CAS is only {cas}. Heavy app usage detected. Try a focus break.",
            "icon": "error",
        })
    
    # ── CAS Trend (if previous available) ──
    if prev_cas is not None:
        delta = cas - prev_cas
        if delta >= 10:
            insights.append({
                "type": "success",
                "title": "📈 Score Improving",
                "body": f"+{delta:.0f} points since last check. Great recovery!",
                "icon": "trending_up",
            })
        elif delta <= -10:
            insights.append({
                "type": "warning",
                "title": "📉 Score Dropping",
                "body": f"{delta:.0f} points since last check. Something distracted you.",
                "icon": "trending_down",
            })
    
    # ── Digital Score Insights ──
    if s_dig < 30:
        insights.append({
            "type": "warning",
            "title": "📱 Heavy App Usage",
            "body": f"Digital score is {s_dig}. Too much time on distracting apps today.",
            "icon": "phone_android",
        })
    elif s_dig > 70:
        insights.append({
            "type": "success",
            "title": "💻 Productive Screen Time",
            "body": f"Digital score is {s_dig}. Mostly productive app usage!",
            "icon": "laptop",
        })
    
    # ── Spatial Score Insights ──
    if s_loc > 20:
        insights.append({
            "type": "success",
            "title": "📍 Great Location",
            "body": "You're spending time in productive zones like library/lab.",
            "icon": "location_on",
        })
    elif s_loc < -10:
        insights.append({
            "type": "info",
            "title": "📍 Location Note",
            "body": "You've been in casual zones. Consider heading to a study area.",
            "icon": "location_off",
        })
    
    # ── Social Score Insights ──
    if s_soc > 10:
        insights.append({
            "type": "success",
            "title": "👥 Positive Social Environment",
            "body": f"Social score is +{s_soc:.0f}. Being around focused peers helps!",
            "icon": "groups",
        })
    elif s_soc < -5:
        insights.append({
            "type": "warning",
            "title": "👥 Social Contagion Alert",
            "body": f"Social score is {s_soc:.0f}. Nearby peers may be affecting your focus.",
            "icon": "person_off",
        })
    
    return insights


# ═══════════════════════════════════════════════════════════
# Analysis Snapshot (polled every 5 min by Flutter)
# ═══════════════════════════════════════════════════════════

@router.get("/analysis/{user_id}")
def get_analysis_snapshot(user_id: int, db: Session = Depends(get_db)):
    """
    Returns fresh CAS + server-pushed insight notifications.
    Flutter polls this every 5 minutes and displays insights in the Notifs tab.
    """
    today = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    record = scoring.calculate_daily_cas(user_id, db, today)
    
    cas = round(record.cas_score, 2)
    s_loc = round(record.spatial_score, 2)
    s_soc = round(record.social_score, 2)
    s_dig = round(record.digital_score, 2)
    
    # Get previous CAS for trend comparison
    prev_cas = None
    prev_record = (
        db.query(DailyScore)
        .filter(DailyScore.user_id == user_id, DailyScore.date != today)
        .order_by(DailyScore.date.desc())
        .first()
    )
    if prev_record:
        prev_cas = prev_record.cas_score
    
    # Generate insight notifications
    insights = generate_insights(cas, s_loc, s_soc, s_dig, prev_cas)
    
    return {
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "date": today,
        "CAS": cas,
        "S_loc": s_loc,
        "S_soc": s_soc,
        "S_dig": s_dig,
        "notifications": insights,
    }


# ═══════════════════════════════════════════════════════════
# Garbage Collector
# ═══════════════════════════════════════════════════════════

@router.post("/gc/{user_id}")
def garbage_collect(user_id: int, db: Session = Depends(get_db)):
    """
    Deletes raw telemetry logs older than 24 hours for a given user.
    DailyScore records → kept forever (they ARE the compressed data)
    """
    cutoff = datetime.datetime.utcnow().timestamp() - (24 * 3600)
    
    counts = {}
    for model, name in [
        (LocationLog, "location"),
        (DigitalLog, "digital"),
        (ProximityLog, "proximity"),
        (NotificationLog, "notification"),
        (EngagementLog, "engagement"),
    ]:
        deleted = db.query(model).filter(
            model.user_id == user_id,
            model.timestamp < cutoff
        ).delete(synchronize_session=False)
        counts[name] = deleted
    
    db.commit()
    
    total = sum(counts.values())
    return {
        "status": "success",
        "deleted_total": total,
        "details": counts,
        "cutoff_utc": datetime.datetime.utcfromtimestamp(cutoff).isoformat(),
    }


# ═══════════════════════════════════════════════════════════
# History (DailyScore records for charts)
# ═══════════════════════════════════════════════════════════

@router.get("/history/{user_id}")
def get_history(user_id: int, days: int = 30, db: Session = Depends(get_db)):
    """Returns the last N days of aggregated DailyScore records."""
    records = (
        db.query(DailyScore)
        .filter(DailyScore.user_id == user_id)
        .order_by(DailyScore.date.desc())
        .limit(days)
        .all()
    )
    
    return {
        "status": "success",
        "count": len(records),
        "scores": [
            {
                "date": r.date,
                "CAS": round(r.cas_score, 2),
                "S_loc": round(r.spatial_score, 2),
                "S_soc": round(r.social_score, 2),
                "S_dig": round(r.digital_score, 2),
            }
            for r in records
        ]
    }
