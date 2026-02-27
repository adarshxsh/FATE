from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import auth, ingestion, analysis

from contextlib import asynccontextmanager
from core.database import engine, Base
import models.domain

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        # Note: we use create_all just for demo. In production usually alembic should be utilized.
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(
    title="FATE Backend",
    description="Full Attention Telemetry Engine MVP",
    version="1.0.0",
    lifespan=lifespan
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
