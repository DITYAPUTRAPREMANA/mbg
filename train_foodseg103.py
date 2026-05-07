"""
Fine-tune SegFormer-B2 on FoodSeg103 (semantic segmentation).

Assumes FoodSeg103 has already been downloaded to:
    data/FoodSeg103/
        img_dir/train/   *.jpg
        img_dir/test/    *.jpg
        ann_dir/train/   *.png   (pixel values = class IDs 0–103)
        ann_dir/test/    *.png

Usage:
    python train_foodseg103.py
    python train_foodseg103.py --epochs 20 --batch-size 4 --lr 6e-5
    python train_foodseg103.py --resume                  # resume from checkpoint
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from PIL import Image
from torch.utils.data import Dataset, DataLoader
from tqdm.auto import tqdm
from loguru import logger
from rich.console import Console

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

from config import (
    FOODSEG103_CLASSES, NUM_CLASSES,
    FOODSEG103_IMG_TRAIN, FOODSEG103_IMG_TEST,
    FOODSEG103_ANN_TRAIN, FOODSEG103_ANN_TEST,
    WEIGHTS_DIR, SEGMENTER_BASE_HF, SEGMENTER_IMGSZ, DEVICE,
)

console = Console()
SAVE_DIR = WEIGHTS_DIR / "foodseg103_segformer"


# ── Dataset ──────────────────────────────────────────────────────────────────

class FoodSeg103Dataset(Dataset):
    """
    Loads (image, mask) pairs from FoodSeg103.

    Mask PNG values are class IDs 0-103.  Class 0 = background is kept as-is.
    """

    def __init__(
        self,
        img_dir: Path,
        ann_dir: Path,
        processor,
        imgsz: int = SEGMENTER_IMGSZ,
        augment: bool = False,
    ):
        self.img_dir  = img_dir
        self.ann_dir  = ann_dir
        self.processor = processor
        self.imgsz    = imgsz
        self.augment  = augment

        self.img_paths = sorted(img_dir.glob("*.jpg")) + sorted(img_dir.glob("*.jpeg"))
        if not self.img_paths:
            raise FileNotFoundError(
                f"No .jpg images found in {img_dir}. "
                "Check that FOODSEG103_ROOT in config.py points to the correct location."
            )
        logger.info(f"Dataset: {len(self.img_paths)} images from {img_dir}")

    def __len__(self) -> int:
        return len(self.img_paths)

    def __getitem__(self, idx: int):
        img_path  = self.img_paths[idx]
        ann_path  = self.ann_dir / (img_path.stem + ".png")

        image = Image.open(img_path).convert("RGB")
        mask  = (
            Image.open(ann_path).convert("L")
            if ann_path.exists()
            else Image.new("L", image.size, 0)
        )

        if self.augment:
            image, mask = _random_flip(image, mask)
            image, mask = _random_crop(image, mask, self.imgsz)
        else:
            image = image.resize((self.imgsz, self.imgsz), Image.BILINEAR)
            mask  = mask.resize((self.imgsz, self.imgsz), Image.NEAREST)

        mask_np = np.array(mask, dtype=np.int64)
        mask_np = np.clip(mask_np, 0, NUM_CLASSES - 1)

        encoding = self.processor(images=image, return_tensors="pt")
        pixel_values = encoding["pixel_values"].squeeze(0)  # (3, H, W)
        labels = torch.from_numpy(mask_np)                  # (H, W)

        return pixel_values, labels


def _random_flip(image: Image.Image, mask: Image.Image):
    if np.random.rand() > 0.5:
        return image.transpose(Image.FLIP_LEFT_RIGHT), mask.transpose(Image.FLIP_LEFT_RIGHT)
    return image, mask


def _random_crop(
    image: Image.Image, mask: Image.Image, size: int
) -> tuple[Image.Image, Image.Image]:
    w, h = image.size
    new_w, new_h = max(w, size), max(h, size)
    image = image.resize((new_w, new_h), Image.BILINEAR)
    mask  = mask.resize((new_w, new_h), Image.NEAREST)
    x = np.random.randint(0, new_w - size + 1)
    y = np.random.randint(0, new_h - size + 1)
    return image.crop((x, y, x + size, y + size)), mask.crop((x, y, x + size, y + size))


# ── Metrics ───────────────────────────────────────────────────────────────────

def mean_iou(pred: np.ndarray, target: np.ndarray, num_classes: int) -> float:
    ious = []
    for c in range(1, num_classes):   # skip background
        pred_c   = pred == c
        target_c = target == c
        inter    = (pred_c & target_c).sum()
        union    = (pred_c | target_c).sum()
        if union == 0:
            continue
        ious.append(inter / union)
    return float(np.mean(ious)) if ious else 0.0


# ── Training ──────────────────────────────────────────────────────────────────

def train(args):
    from transformers import (
        AutoConfig,
        SegformerForSemanticSegmentation,
        SegformerImageProcessor,
    )
    import torch.nn.functional as F

    device = args.device
    console.print(f"\n[bold]FoodSeg103 SegFormer Training[/bold]")
    console.print(f"Device  : {device}")
    console.print(f"Epochs  : {args.epochs}")
    console.print(f"Batch   : {args.batch_size}")
    console.print(f"LR      : {args.lr}")
    console.print(f"Save to : {SAVE_DIR}\n")

    # ── processor + model ────────────────────────────────────────────────────
    id2label = {i: c for i, c in enumerate(FOODSEG103_CLASSES)}
    label2id = {c: i for i, c in enumerate(FOODSEG103_CLASSES)}

    processor = SegformerImageProcessor(
        do_resize=True,
        size={"height": args.imgsz, "width": args.imgsz},
        do_normalize=True,
    )

    if args.resume and SAVE_DIR.exists():
        console.print(f"Resuming from {SAVE_DIR}")
        model = SegformerForSemanticSegmentation.from_pretrained(
            str(SAVE_DIR),
            use_safetensors=True,
        )
    else:
        console.print(f"Loading base model: {SEGMENTER_BASE_HF}")
        cfg = AutoConfig.from_pretrained(SEGMENTER_BASE_HF)
        cfg.num_labels = NUM_CLASSES
        cfg.id2label = id2label
        cfg.label2id = label2id
        model = SegformerForSemanticSegmentation.from_pretrained(
            SEGMENTER_BASE_HF,
            config=cfg,
            ignore_mismatched_sizes=True,
            use_safetensors=True,
        )

    model.to(device)

    # ── datasets & loaders ───────────────────────────────────────────────────
    train_ds = FoodSeg103Dataset(
        FOODSEG103_IMG_TRAIN, FOODSEG103_ANN_TRAIN,
        processor, imgsz=args.imgsz, augment=True,
    )
    val_ds = FoodSeg103Dataset(
        FOODSEG103_IMG_TEST, FOODSEG103_ANN_TEST,
        processor, imgsz=args.imgsz, augment=False,
    )

    train_loader = DataLoader(
        train_ds,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.workers,
        pin_memory=(device == "cuda"),
    )
    val_loader = DataLoader(
        val_ds,
        batch_size=max(1, args.batch_size // 2),
        shuffle=False,
        num_workers=args.workers,
        pin_memory=(device == "cuda"),
    )

    console.print(
        f"Train: {len(train_ds):,} images | "
        f"Val: {len(val_ds):,} images\n"
    )

    # ── optimiser + scheduler ─────────────────────────────────────────────────
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-2)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=args.epochs, eta_min=args.lr * 0.05
    )
    use_amp = device == "cuda"
    scaler  = torch.amp.GradScaler("cuda", enabled=use_amp)

    SAVE_DIR.mkdir(parents=True, exist_ok=True)
    best_miou = 0.0

    for epoch in range(1, args.epochs + 1):
        # ── train ────────────────────────────────────────────────────────────
        model.train()
        t0 = time.perf_counter()
        total_loss, n_batches = 0.0, 0

        train_pbar = tqdm(
            train_loader,
            total=len(train_loader),
            desc=f"Epoch {epoch:02d}/{args.epochs} [train]",
            dynamic_ncols=True,
        )

        for pixel_values, labels in train_pbar:
            pixel_values = pixel_values.to(device)
            labels       = labels.to(device)

            optimizer.zero_grad()
            with torch.amp.autocast("cuda", enabled=use_amp):
                outputs = model(pixel_values=pixel_values, labels=labels)
                loss    = outputs.loss

            if use_amp:
                scaler.scale(loss).backward()
                scaler.unscale_(optimizer)
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler.step(optimizer)
                scaler.update()
            else:
                loss.backward()
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()

            total_loss += loss.item()
            n_batches  += 1
            train_pbar.set_postfix(loss=f"{(total_loss / max(n_batches, 1)):.4f}")

        scheduler.step()
        avg_loss = total_loss / max(n_batches, 1)

        # ── validate ─────────────────────────────────────────────────────────
        model.eval()
        miou_scores = []
        with torch.no_grad():
            val_pbar = tqdm(
                val_loader,
                total=len(val_loader),
                desc=f"Epoch {epoch:02d}/{args.epochs} [val]",
                dynamic_ncols=True,
            )
            for pixel_values, labels in val_pbar:
                pixel_values = pixel_values.to(device)
                outputs = model(pixel_values=pixel_values)
                logits  = outputs.logits  # (B, C, H/4, W/4)

                upsampled = F.interpolate(
                    logits,
                    size=labels.shape[-2:],
                    mode="bilinear",
                    align_corners=False,
                )
                preds = upsampled.argmax(dim=1).cpu().numpy()
                for pred, gt in zip(preds, labels.numpy()):
                    miou_scores.append(mean_iou(pred, gt, NUM_CLASSES))
                val_pbar.set_postfix(mIoU=f"{(float(np.mean(miou_scores)) if miou_scores else 0.0):.4f}")

        val_miou = float(np.mean(miou_scores)) if miou_scores else 0.0
        elapsed  = time.perf_counter() - t0

        console.print(
            f"Epoch {epoch:02d}/{args.epochs}  |  "
            f"loss {avg_loss:.4f}  |  "
            f"val mIoU {val_miou:.4f}  |  "
            f"{elapsed:.0f}s"
        )

        if val_miou > best_miou:
            best_miou = val_miou
            model.save_pretrained(str(SAVE_DIR), safe_serialization=True)
            processor.save_pretrained(str(SAVE_DIR))
            console.print(f"  [green]Saved best model (mIoU={val_miou:.4f})[/green]")

    # Save class map
    with open(SAVE_DIR / "foodseg103_classes.json", "w") as f:
        json.dump(FOODSEG103_CLASSES, f, indent=2)

    console.print(
        f"\n[bold green]Training complete.  Best val mIoU: {best_miou:.4f}[/bold green]"
    )
    console.print(f"Model saved to: {SAVE_DIR}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Fine-tune SegFormer-B2 on FoodSeg103"
    )
    parser.add_argument("--epochs",     type=int,   default=20,
                        help="Default 20 for 6GB GPU (adjust based on VRAM)")
    parser.add_argument("--batch-size", type=int,   default=2,
                        help="Batch size (default 2 for 6GB VRAM, use 4+ for 8GB+)")
    parser.add_argument("--lr",         type=float, default=6e-5)
    parser.add_argument("--imgsz",      type=int,   default=384,
                        help="Image size (default 384 for 6GB GPU, use 512 for 8GB+)")
    parser.add_argument("--workers",    type=int,   default=2,
                        help="DataLoader workers (2-4 recommended)")
    parser.add_argument("--device",     type=str,   default=DEVICE)
    parser.add_argument("--resume",     action="store_true",
                        help="Resume training from existing checkpoint in weights/")
    args = parser.parse_args()

    train(args)


if __name__ == "__main__":
    main()
