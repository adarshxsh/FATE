from fastapi import APIRouter
from core import scoring

router = APIRouter()

@router.get("/dashboard")
async def get_dashboard(user_email: str):
    # Mock aggregation for demonstration
    mock_s_loc = scoring.calculate_spatial_score("Library", 2.0)
    mock_s_soc = scoring.calculate_social_score(5, True)
    
    # Mocking Digital score using new API logic
    # Assume 45 minutes on Entertainment app and ignored a social notification
    app_score = scoring.calculate_digital_score("ENTERTAINMENT", 2700)
    notif_score = scoring.calculate_notification_score("SOCIAL", "someone liked your reel", None)
    
    mock_s_dig = app_score + notif_score
    
    cas = scoring.compute_cas(mock_s_loc, mock_s_soc, mock_s_dig)
    
    return {
        "user": user_email,
        "CAS": cas,
        "S_loc": mock_s_loc,
        "S_soc": mock_s_soc,
        "S_dig": mock_s_dig,
        "ai_insight": "Your focus peaks in the Library syntax, but Instagram notifications degrade your cognitive retention."
    }
