FATE (Full Attention Telemetry Engine)
Ideathon Submission – Campus Attention Economy

1. Problem
College students suffer from attention fragmentation due to uncontrolled digital stimuli.
Constant notifications and app switching reduce deep-work capacity.
Existing tools rely on willpower instead of behavioral intelligence.

2. Solution
FATE is a campus-aware attention telemetry system.
It passively monitors digital behavior and environment context.
It computes a Cumulative Attention Score (CAS).
It provides AI-generated focus optimization insights.

3. Core Idea
Measure attention objectively.
Correlate digital activity + location + peer proximity.
Apply behavioral friction instead of hard app blocking.
Gamify productivity inside a university ecosystem.

4. Architecture Overview
Android App (Flutter + Kotlin)
FastAPI Backend
AI Insight Engine (Embeddings + Retrieval)
JWT-based Authentication (@iitj.ac.in only)

-----------------------------------------
ANDROID ARCHITECTURE
-----------------------------------------

Presentation Layer (Flutter UI)
- Attention Dashboard
- Activity Timeline
- Context Intelligence Panel
- Insights Screen
- Privacy Controls

Application Logic Layer
- TelemetryController
- AttentionEngine
- ContextCorrelationEngine
- InsightEngine
- LocalMetricsRepository

Native Telemetry Layer (Kotlin)
- NotificationTelemetryService
- UsageTelemetryManager
- BluetoothTelemetryManager
- WifiTelemetryManager
- LocationTelemetryManager
- ContentAnalyzer
- TelemetryEventBus

Android APIs Used
- NotificationListenerService
- UsageStatsManager
- BluetoothLeScanner
- WifiManager
- FusedLocationProviderClient

-----------------------------------------
BACKEND (FastAPI)
-----------------------------------------

Authentication
- Google OAuth verification
- Domain restricted to @iitj.ac.in
- JWT issuance

Data Ingestion
- /ingest/location
- /ingest/proximity
- /ingest/digital

-----------------------------------------
SCORING MODEL
-----------------------------------------

Spatial Score: Time in zone × zone weight
Social Score: Time with peer × peer multiplier × synergy
Digital Score: App score − notification penalty

Notification Penalty:
P = Σ (k / (Δt + 1))

Final Score:
CAS = αS_loc + βS_soc + γS_dig
Normalized to 0–100 scale.
-----------------------------------------