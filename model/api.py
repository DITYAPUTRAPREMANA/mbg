"""
MBG FastAPI backend — segmentation edition.

Run:
    uvicorn api:app --host 0.0.0.0 --port 8000 --reload
"""

from __future__ import annotations

import io
import sys
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Optional

import torch
import requests as req_lib
from fastapi import FastAPI, File, UploadFile, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from PIL import Image
from loguru import logger
from pydantic import BaseModel
from pyngrok import ngrok

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pipeline import MBGPipeline, get_pipeline
from nutrition import NutritionDB, NutritionService


# ── Pydantic models ──────────────────────────────────────────────────────────

class NutritionOut(BaseModel):
    food_name:      Optional[str]   = None
    calories:       Optional[float] = None
    protein_g:      Optional[float] = None
    fat_g:          Optional[float] = None
    carbohydrate_g: Optional[float] = None
    fiber_g:        Optional[float] = None
    sugar_g:        Optional[float] = None
    sodium_mg:      Optional[float] = None
    source:         Optional[str]   = None


class SegmentOut(BaseModel):
    label:       str
    class_id:    int
    pixel_count: int
    area_cm2:    float
    volume_cm3:  float
    confidence:  float
    color:       list[int]          # [R, G, B]
    nutrition:   NutritionOut


class AnalyzeResponse(BaseModel):
    total_items:         int
    processing_time_ms:  float
    items:               list[SegmentOut]
    aggregate_nutrition: NutritionOut


class HealthResponse(BaseModel):
    status:      str
    version:     str
    device:      str
    db_size:     int
    model_ready: bool


# ── Lifecycle ────────────────────────────────────────────────────────────────

_pipeline: Optional["MBGPipeline"] = None
_nutrition_db: Optional[NutritionDB] = None
_nutrition_svc: Optional[NutritionService] = None
_ngrok_url: Optional[str] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _pipeline, _nutrition_db, _nutrition_svc, _ngrok_url
    logger.info("Starting MBG API (segmentation edition)...")
    _pipeline      = get_pipeline()
    _nutrition_db  = NutritionDB()
    _nutrition_svc = NutritionService(_nutrition_db)
    
    # Start ngrok tunnel
    try:
        tunnel = ngrok.connect("8000", "http")
        # Extract the public URL from the tunnel object
        _ngrok_url = str(tunnel).split('"')[1] if '"' in str(tunnel) else str(tunnel)
        logger.info(f"✓ Ngrok tunnel established: {_ngrok_url}")
        print(f"\n{'='*70}")
        print(f"  ✓ PUBLIC URL (akses dari mana saja): {_ngrok_url}")
        print(f"  ✓ LOCAL URL (akses lokal):            http://localhost:8000")
        print(f"  ✓ DOCS (dokumentasi API):             {_ngrok_url}/docs")
        print(f"{'='*70}\n")
    except Exception as e:
        logger.error(f"Failed to start ngrok: {e}")
        print(f"\n⚠ Ngrok error: {e}")
        print(f"  Pastikan ngrok sudah terinstall: pip install pyngrok\n")
    
    logger.info("MBG API ready.")
    yield
    logger.info("Shutting down MBG API.")
    if _ngrok_url:
        try:
            ngrok.disconnect(_ngrok_url)
            ngrok.kill()
        except Exception as e:
            logger.warning(f"Error disconnecting ngrok: {e}")


app = FastAPI(
    title="MBG – Meal-Based Nutrition Guide (FoodSeg103 edition)",
    version="0.2.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _load_image(data: bytes) -> Image.Image:
    try:
        return Image.open(io.BytesIO(data)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file.")


def _result_to_response(result: dict) -> dict:
    items = []
    for item in result["items"]:
        items.append({
            "label":       item["label"],
            "class_id":    item["class_id"],
            "pixel_count": item["pixel_count"],
            "area_cm2":    item["area_cm2"],
            "volume_cm3":  item["volume_cm3"],
            "confidence":  item["confidence"],
            "color":       list(item["color"]),
            "nutrition":   item["nutrition"],
        })
    return {
        "total_items":         result["total_items"],
        "processing_time_ms":  result["processing_time_ms"],
        "items":               items,
        "aggregate_nutrition": result["aggregate_nutrition"],
    }


def _run_and_check(image: Image.Image) -> dict:
    if _pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not initialised.")
    return _pipeline.run(image)


# ── Routes ───────────────────────────────────────────────────────────────────

@app.get("/", tags=["system"])
async def root():
    return {"name": "MBG FoodSeg103 Prototype", "docs": "/docs", "health": "/health"}


@app.get("/health", response_model=HealthResponse, tags=["system"])
async def health():
    ready = _pipeline is not None and _pipeline.segmenter.is_finetuned
    assert _nutrition_db is not None
    return {
        "status":      "ok",
        "version":     "0.2.0",
        "device":      "cuda" if torch.cuda.is_available() else "cpu",
        "db_size":     _nutrition_db.count(),
        "model_ready": ready,
    }


@app.post("/analyze/", response_model=AnalyzeResponse, tags=["inference"])
async def analyze_upload(file: UploadFile = File(...)):
    """Upload an image for food segmentation and nutrition analysis."""
    data  = await file.read()
    image = _load_image(data)
    result = _run_and_check(image)
    return _result_to_response(result)


@app.post("/analyze/url", response_model=AnalyzeResponse, tags=["inference"])
async def analyze_url(
    image_url: str = Query(..., description="Public URL of a food image")
):
    """Analyse a food image from a URL."""
    try:
        resp = req_lib.get(image_url, timeout=10)
        resp.raise_for_status()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not fetch image: {e}")
    image  = _load_image(resp.content)
    result = _run_and_check(image)
    return _result_to_response(result)


@app.post("/analyze/overlay", tags=["inference"])
async def analyze_overlay(file: UploadFile = File(...)):
    """
    Upload an image and receive a PNG with the coloured segmentation
    mask blended over the original (no JSON — image bytes only).
    """
    data   = await file.read()
    image  = _load_image(data)
    result = _run_and_check(image)
    buf = io.BytesIO()
    result["overlay"].convert("RGB").save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")


@app.get("/nutrition/search", tags=["nutrition"])
async def search_nutrition(
    q:     str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50),
):
    assert _nutrition_svc is not None
    results = _nutrition_svc.search(q, limit)
    return {"query": q, "count": len(results), "results": results}


@app.get("/nutrition/lookup/{food_name}", tags=["nutrition"])
async def lookup_nutrition(food_name: str):
    assert _nutrition_svc is not None
    return _nutrition_svc.lookup(food_name)


@app.get("/nutrition/stats", tags=["nutrition"])
async def nutrition_stats():
    assert _nutrition_db is not None
    return {"total_records": _nutrition_db.count()}


@app.get("/classes", tags=["model"])
async def list_classes():
    """Return the full FoodSeg103 class list."""
    from config import FOODSEG103_CLASSES
    return {
        "count":   len(FOODSEG103_CLASSES),
        "classes": {i: c for i, c in enumerate(FOODSEG103_CLASSES)},
    }
