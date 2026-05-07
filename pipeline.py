"""
MBG inference pipeline (segmentation edition).

image → FoodSegmenter → segments → NutritionService → result
"""

from __future__ import annotations

import time
from typing import Optional

from PIL import Image
from loguru import logger

from segmenter import FoodSegmenter
from nutrition import NutritionDB, NutritionService, aggregate_nutrition
from config import DEVICE


class MBGPipeline:
    def __init__(self):
        logger.info(f"Initialising MBG pipeline on {DEVICE}")
        self.segmenter = FoodSegmenter()
        self.nutrition  = NutritionService(NutritionDB())
        logger.info("Pipeline ready.")

    def run(self, image: Image.Image) -> dict:
        """
        Run full pipeline on a PIL image.

        Returns
        -------
        dict
            total_items         : int
            processing_time_ms  : float
            overlay             : PIL.Image   (coloured mask blended over original)
            items               : list[dict]
                label           : str          food class name
                class_id        : int
                pixel_count     : int
                area_cm2        : float        projected area in cm²
                volume_cm3      : float        estimated volume in cm³
                confidence      : float        mean softmax confidence
                color           : (R,G,B)
                nutrition       : dict         nutrition per 100 g
            aggregate_nutrition : dict         summed nutrition for whole meal
        """
        t0 = time.perf_counter()

        seg_result = self.segmenter.segment(image)
        segments   = seg_result["segments"]

        items = []
        for seg in segments:
            nut = self.nutrition.lookup(seg["label"])
            item = {**seg, "nutrition": nut}
            items.append(item)

        # Fallback: if model produced no segments, log a warning.
        if not items:
            logger.warning(
                "Segmenter returned no food regions. "
                "Model may not be fine-tuned yet — run train_foodseg103.py."
            )

        agg = aggregate_nutrition([it["nutrition"] for it in items])
        elapsed_ms = (time.perf_counter() - t0) * 1000

        return {
            "total_items":         len(items),
            "processing_time_ms":  round(elapsed_ms, 2),
            "overlay":             seg_result["overlay"],
            "mask":                seg_result["mask"],
            "items":               items,
            "aggregate_nutrition": agg,
        }


# Singleton for API / Streamlit reuse
_pipeline: Optional[MBGPipeline] = None


def get_pipeline() -> MBGPipeline:
    global _pipeline
    if _pipeline is None:
        _pipeline = MBGPipeline()
    return _pipeline
