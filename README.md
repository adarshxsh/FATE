# FATE (Full Attention Telemetry Engine)

FATE is a campus-aware attention telemetry system and digital wellness platform. It is designed to track, measure, and optimize user attention by passively monitoring digital behavior, physical location, and social proximity.

Through intelligent behavioral analysis, FATE calculates a **Cumulative Attention Score (CAS)** to gamify productivity and help individuals break free from constant context switching and notification fatigue.

---

## 🌟 Key Features

### 1. **Proximity & Social Telemetry**
- **Peer Discovery**: Uses the **Google Nearby Connections API** to dynamically discover and broadcast nearby peers across Bluetooth and Wi-Fi Direct.
- **Identity Broadcasting**: Integrates with Google Sign-in to natively broadcast Google Display names, or fallbacks to the Android device model.
- **Close Friends Exclusion**: Lets users exclude specific devices from scoring to differentiate between constructive social synergy and distractions.
- **Engagement Tracking**: Tracks physical proximity engagement duration using peer-found and peer-lost events.

### 2. **Digital Usage & Fragmentation**
- **Robust App Analytics**: Natively queries the Android `UsageStatsManager` in Kotlin to get granular time spent per application and detect application context switches.
- **Notification Listener**: Employs an Android `NotificationListenerService` to intercept incoming notifications.
- **Response Penalty Engine**: Flags fragmentation by measuring the exact time taken to respond to a notification (post time vs click/app switch time).

### 3. **Spatial Awareness & Location Engine**
- Tracks geographical movements to evaluate stationary work sessions vs. active movement.
- Maps coordinates to specific "Neutral Zones" (e.g., Hostels) where users are legitimately taking a break, automatically applying a non-penalizing flat base score (0.0).

### 4. **Algorithmic CAS Engine (Settings Priorities)**
Combines three weighted pillars into the Cumulative Attention Score:
- **Spatial Score**: Based on productive location duration and geofences.
- **Social Score**: Based on interaction lengths and peer multipliers.
- **Digital Score**: App productivity scores penalized heavily by notification fragmentation.
- *Users can dynamically update their weights for these three metrics via the App Dashboard.*

---

## 🏗️ Architecture

FATE operates across three deeply integrated layers:

1. **Frontend (Flutter)**
   - Delivers an intuitive dashboard to view logs, nearby peers, and real-time scores.
   - Handles user Google OAuth 2.0 Identity.
2. **Native Telemetry (Android/Kotlin)**
   - Employs Flutter `MethodChannel` and `EventChannel` to run headless native services.
   - Native Managers: [UsageTelemetryManager](cci:2://file:///home/yash/FATE/fate_app/android/app/src/main/kotlin/com/example/fate_app/telemetry/UsageTelemetryManager.kt:6:0-92:1), `LocationTelemetryManager`, [ProximityTelemetryManager](cci:2://file:///home/yash/FATE/fate_app/android/app/src/main/kotlin/com/example/fate_app/telemetry/ProximityTelemetryManager.kt:10:0-103:1), configured to bypass Android background-execution limits.
3. **Backend Scoring Engine (Python FastAPI)**
   - High-throughput ingestion API for telemetry payloads (`/location`, `/proximity`, `/digital`).
   - Stores logs and mappings in a **PostgreSQL** Database via SQLAlchemy.
   - Built-in Garbage Collection sweeps logs older than 24 hours to prevent db bloating.
   - Configured for Render deployment.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/) `>= 3.10.7`
- [Python](https://www.python.org/) `>= 3.11`
- [Java JDK](https://openjdk.org/) `17` or `21`
- Firebase Project (for Auth & google-services.json)

### Backend Deployment (Local)

```bash
cd fate_server
# Create a virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the Telemetry FastApi Server
uvicorn main:app --reload
