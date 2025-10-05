#!/usr/bin/env python3
"""Simple health check API service."""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from datetime import datetime

app = FastAPI(title="Health Check API", version="1.0.0")


@app.get("/health")
async def health_check():
    """Health check endpoint that returns success."""
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "service": "health-api"
        }
    )


@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint."""
    return JSONResponse(
        status_code=200,
        content={
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat(),
            "service": "health-api"
        }
    )


@app.get("/live")
async def liveness_check():
    """Liveness check endpoint."""
    return JSONResponse(
        status_code=200,
        content={
            "status": "alive",
            "timestamp": datetime.utcnow().isoformat(),
            "service": "health-api"
        }
    )


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "service": "Health Check API",
        "version": "1.0.0",
        "endpoints": {
            "/health": "General health check",
            "/ready": "Readiness probe",
            "/live": "Liveness probe"
        }
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
