"""
Food semantic segmenter using SegFormer fine-tuned on FoodSeg103.

Returns per-pixel class masks instead of bounding boxes.
Falls back to a freshly initialised SegFormer (random classifier head)
when fine-tuned weights are not yet available — run train_foodseg103.py first
to get useful predictions.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from loguru import logger

from config import (
    DEVICE,
    SEGMENTER_WEIGHTS,
    SEGMENTER_BASE_HF,
    SEGMENTER_IMGSZ,
    SEGMENTER_CONF_THR,
    MIN_SEGMENT_RATIO,
    FOODSEG103_CLASSES,
    NUM_CLASSES,
    PIXELS_PER_CM2,
    FOOD_HEIGHT_CM,
    DEFAULT_FOOD_HEIGHT_CM,
)

# Colour palette: one RGB colour per class (visually distinct)
np.random.seed(42)
_PALETTE = np.random.randint(60, 230, size=(NUM_CLASSES, 3), dtype=np.uint8)
_PALETTE[0] = [0, 0, 0]   # background → black


def _label_to_color(label_idx: int) -> tuple[int, int, int]:
    return tuple(_PALETTE[label_idx % NUM_CLASSES].tolist())


def _estimate_volume(pixel_count: int, label: str) -> float:
    """
    Estimate volume in cm³.

    Calibration assumption: 30 pixels = 1 cm  →  900 px² = 1 cm².
    Volume ≈ projected_area_cm² × estimated_height_cm.
    """
    area_cm2 = pixel_count / PIXELS_PER_CM2
    height_cm = FOOD_HEIGHT_CM.get(label, DEFAULT_FOOD_HEIGHT_CM)
    return round(area_cm2 * height_cm, 2)


class FoodSegmenter:
    """
    Wraps a SegFormer model for semantic segmentation on FoodSeg103.

    Parameters
    ----------
    weights_dir : str
        Path to a HuggingFace-style saved model directory produced by
        ``train_foodseg103.py``.  When absent, a fresh SegFormer encoder
        is loaded from HuggingFace Hub with a randomly initialised
        classification head.
    confidence_thr : float
        Segments whose max softmax probability is below this threshold
        are discarded.
    min_segment_ratio : float
        Segments covering less than this fraction of the total image area
        are discarded.
    device : str
        "cuda" or "cpu".
    """

    def __init__(
        self,
        weights_dir: str = SEGMENTER_WEIGHTS,
        confidence_thr: float = SEGMENTER_CONF_THR,
        min_segment_ratio: float = MIN_SEGMENT_RATIO,
        imgsz: int = SEGMENTER_IMGSZ,
        device: str = DEVICE,
    ):
        self.confidence_thr    = confidence_thr
        self.min_segment_ratio = min_segment_ratio
        self.imgsz             = imgsz
        self.device            = device
        self.classes           = FOODSEG103_CLASSES

        self._load_model(Path(weights_dir))

    # ── model loading ────────────────────────────────────────────────────────

    def _load_model(self, weights_dir: Path):
        from transformers import (
            AutoConfig,
            SegformerForSemanticSegmentation,
            SegformerImageProcessor,
        )

        if weights_dir.exists() and (weights_dir / "config.json").exists():
            logger.info(f"Loading fine-tuned SegFormer from {weights_dir}")
            self.processor = SegformerImageProcessor.from_pretrained(str(weights_dir))
            self.model = SegformerForSemanticSegmentation.from_pretrained(
                str(weights_dir),
                use_safetensors=True,
            )
            self._finetuned = True
        else:
            logger.warning(
                f"Fine-tuned weights not found at {weights_dir}. "
                "Loading base encoder with random classification head. "
                "Run train_foodseg103.py to get proper predictions."
            )
            id2label = {i: c for i, c in enumerate(self.classes)}
            label2id = {c: i for i, c in enumerate(self.classes)}
            self.processor = SegformerImageProcessor(
                do_resize=True,
                size={"height": self.imgsz, "width": self.imgsz},
                do_normalize=True,
            )
            cfg = AutoConfig.from_pretrained(SEGMENTER_BASE_HF)
            cfg.num_labels = NUM_CLASSES
            cfg.id2label = id2label
            cfg.label2id = label2id
            self.model = SegformerForSemanticSegmentation.from_pretrained(
                SEGMENTER_BASE_HF,
                config=cfg,
                ignore_mismatched_sizes=True,
                use_safetensors=True,
            )
            self._finetuned = False

        self.model.to(self.device).eval()
        logger.info(
            f"FoodSegmenter ready | device={self.device} | "
            f"fine-tuned={self._finetuned} | classes={NUM_CLASSES}"
        )

    # ── public API ───────────────────────────────────────────────────────────

    @torch.no_grad()
    def segment(self, image: Image.Image) -> dict:
        """
        Segment a PIL image.

        Returns
        -------
        dict with keys:
            mask       : np.ndarray (H, W) of int32 class IDs
            overlay    : PIL.Image  colour overlay (RGBA)
            segments   : list[dict] — one entry per detected food class
                {
                  label       : str,
                  class_id    : int,
                  pixel_count : int,
                  area_cm2    : float,
                  volume_cm3  : float,
                  confidence  : float,   # mean max-softmax over segment pixels
                  color       : (R,G,B),
                }
        """
        orig_w, orig_h = image.size
        image_rgb = image.convert("RGB")

        inputs = self.processor(images=image_rgb, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        outputs = self.model(**inputs)

        # logits: (1, num_classes, H/4, W/4)  → upsample to original size
        logits = outputs.logits  # (1, C, h, w)
        upsampled = F.interpolate(
            logits,
            size=(orig_h, orig_w),
            mode="bilinear",
            align_corners=False,
        )  # (1, C, H, W)

        probs = torch.softmax(upsampled, dim=1)[0]   # (C, H, W)
        conf_map, pred_mask = probs.max(dim=0)       # each (H, W)

        pred_mask_np = pred_mask.cpu().numpy().astype(np.int32)
        conf_map_np  = conf_map.cpu().numpy()

        # Apply confidence threshold: low-confidence pixels → background
        pred_mask_np[conf_map_np < self.confidence_thr] = 0

        image_area = orig_h * orig_w

        # Build per-class segment dicts (ignore background = 0)
        unique_ids = np.unique(pred_mask_np)
        segments: list[dict] = []
        for cls_id in unique_ids:
            if cls_id == 0:
                continue
            pixel_mask = pred_mask_np == cls_id
            pixel_count = int(pixel_mask.sum())
            if pixel_count / image_area < self.min_segment_ratio:
                continue

            label = self.classes[cls_id] if cls_id < len(self.classes) else "other ingredients"
            mean_conf = float(conf_map_np[pixel_mask].mean())
            area_cm2  = round(pixel_count / PIXELS_PER_CM2, 4)
            volume    = _estimate_volume(pixel_count, label)

            segments.append({
                "label":       label,
                "class_id":    int(cls_id),
                "pixel_count": pixel_count,
                "area_cm2":    area_cm2,
                "volume_cm3":  volume,
                "confidence":  round(mean_conf, 4),
                "color":       _label_to_color(cls_id),
            })

        # Sort by pixel count descending
        segments.sort(key=lambda s: s["pixel_count"], reverse=True)

        overlay = self._make_overlay(image_rgb, pred_mask_np, alpha=160)

        return {
            "mask":     pred_mask_np,
            "overlay":  overlay,
            "segments": segments,
        }

    # ── helpers ──────────────────────────────────────────────────────────────

    @staticmethod
    def _make_overlay(
        image: Image.Image,
        mask: np.ndarray,
        alpha: int = 160,
    ) -> Image.Image:
        """
        Blend coloured segmentation mask over the original image (RGBA).
        """
        colour_mask = _PALETTE[mask % NUM_CLASSES]  # (H, W, 3)
        overlay_rgb = Image.fromarray(colour_mask.astype(np.uint8), mode="RGB")
        overlay_rgba = overlay_rgb.convert("RGBA")

        # Set alpha: 0 for background pixels, `alpha` for food pixels
        mask_alpha = np.where(mask == 0, 0, alpha).astype(np.uint8)
        r, g, b, _ = overlay_rgba.split()
        overlay_rgba = Image.merge("RGBA", (r, g, b, Image.fromarray(mask_alpha)))

        base_rgba = image.convert("RGBA")
        blended   = Image.alpha_composite(base_rgba, overlay_rgba)
        return blended

    @property
    def is_finetuned(self) -> bool:
        return self._finetuned
