from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import auth, ingestion, analysis

app = FastAPI(
    title="FATE Backend",
    description="Full Attention Telemetry Engine MVP",
    version="1.0.0"
)

# Allow Flutter app to communicate with FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(ingestion.router, prefix="/api/ingest", tags=["Telemetry Ingestion"])
app.include_router(analysis.router, prefix="/api/analysis", tags=["Insights & Score"])

@app.get("/")
async def root():
    return {"status": "ok", "message": "FATE Core Engine Running"}
