"""
MBG Local Prototype Setup — FoodSeg103 segmentation edition.

Downloads:
  - SegFormer-B2 encoder weights from HuggingFace Hub
  - Seeds the local nutrition SQLite database from CSV

Usage:
    python setup.py              # download encoder + seed DB
    python setup.py --check      # environment check only
"""

import argparse
import importlib.metadata as importlib_metadata
import sys
from pathlib import Path

from loguru import logger
from rich.console import Console
from rich.table import Table

console = Console()

BASE_DIR    = Path(__file__).resolve().parent
WEIGHTS_DIR = BASE_DIR / "weights"
DATA_DIR    = BASE_DIR / "data"

WEIGHTS_DIR.mkdir(exist_ok=True)
DATA_DIR.mkdir(exist_ok=True)


# ── Environment check ─────────────────────────────────────────────────────────

def check_environment():
    console.print("\n[bold]MBG Environment Check[/bold]\n")
    console.print(f"Python: [cyan]{sys.executable}[/cyan]")
    rows = []

    try:
        import torch
        cuda = torch.cuda.is_available()
        rows.append(("PyTorch", torch.__version__, "ok"))
        rows.append(("CUDA/ROCm", str(cuda), "ok" if cuda else "warn"))
        if cuda:
            rows.append(("GPU", torch.cuda.get_device_name(0), "ok"))
            mem_gb = torch.cuda.get_device_properties(0).total_memory / 1e9
            rows.append(("VRAM", f"{mem_gb:.1f} GB", "ok"))
    except ImportError:
        rows.append(("PyTorch", "NOT INSTALLED", "error"))

    package_checks = [
        ("transformers", "transformers"),
        ("datasets", "datasets"),
        ("PIL", "Pillow"),
        ("fastapi", "fastapi"),
        ("streamlit", "streamlit"),
        ("plotly", "plotly"),
        ("loguru", "loguru"),
        ("rich", "rich"),
    ]

    for label, dist_name in package_checks:
        try:
            ver = importlib_metadata.version(dist_name)
            rows.append((label, ver, "ok"))
        except importlib_metadata.PackageNotFoundError:
            rows.append((label, "NOT INSTALLED", "error"))

    table = Table(show_header=True, header_style="bold cyan")
    table.add_column("Package")
    table.add_column("Version / Status")
    table.add_column("State")
    for name, val, state in rows:
        color = {"ok": "green", "warn": "yellow", "error": "red"}[state]
        table.add_row(name, val, f"[{color}]{state}[/{color}]")
    console.print(table)

    errors = [r for r in rows if r[2] == "error"]
    if errors:
        console.print("\n[red]Fix errors before running the app.[/red]")
        console.print(f"Run: {sys.executable} -m pip install -r requirements.txt")
        sys.exit(1)
    else:
        console.print("\n[green]Environment OK.[/green]")


# ── Model pre-fetch ───────────────────────────────────────────────────────────

def download_encoder():
    """
    Pre-fetch SegFormer-B2 encoder weights from HuggingFace Hub so that
    the first segmenter load is fast (cached in ~/.cache/huggingface/).
    """
    console.print("\nPre-fetching SegFormer-B2 encoder weights from HuggingFace…")
    try:
        from transformers import AutoConfig, SegformerImageProcessor, SegformerForSemanticSegmentation
        sys.path.insert(0, str(BASE_DIR))
        from config import SEGMENTER_BASE_HF, NUM_CLASSES, FOODSEG103_CLASSES

        id2label = {i: c for i, c in enumerate(FOODSEG103_CLASSES)}
        label2id = {c: i for i, c in enumerate(FOODSEG103_CLASSES)}
        cfg = AutoConfig.from_pretrained(SEGMENTER_BASE_HF)
        cfg.num_labels = NUM_CLASSES
        cfg.id2label = id2label
        cfg.label2id = label2id

        SegformerImageProcessor.from_pretrained(SEGMENTER_BASE_HF)
        SegformerForSemanticSegmentation.from_pretrained(
            SEGMENTER_BASE_HF,
            config=cfg,
            ignore_mismatched_sizes=True,
            use_safetensors=True,
        )
        console.print(f"[green]SegFormer-B2 encoder ready.[/green]")
    except Exception as e:
        console.print(f"[yellow]Could not pre-fetch encoder: {e}[/yellow]")
        console.print("It will be downloaded automatically on first run.")


def check_dataset():
    """Verify FoodSeg103 dataset layout."""
    sys.path.insert(0, str(BASE_DIR))
    from config import (
        FOODSEG103_ROOT,
        FOODSEG103_IMG_TRAIN, FOODSEG103_IMG_TEST,
        FOODSEG103_ANN_TRAIN, FOODSEG103_ANN_TEST,
    )

    console.print("\nChecking FoodSeg103 dataset…")
    all_ok = True
    for name, path in [
        ("img_dir/train", FOODSEG103_IMG_TRAIN),
        ("img_dir/test",  FOODSEG103_IMG_TEST),
        ("ann_dir/train", FOODSEG103_ANN_TRAIN),
        ("ann_dir/test",  FOODSEG103_ANN_TEST),
    ]:
        exists = path.exists()
        count  = len(list(path.glob("*"))) if exists else 0
        status = "ok" if (exists and count > 0) else "missing"
        color  = "green" if status == "ok" else "red"
        console.print(f"  [{color}]{status}[/{color}]  {name}  ({count} files)  — {path}")
        if status != "ok":
            all_ok = False

    if not all_ok:
        console.print(
            "\n[yellow]FoodSeg103 not found or incomplete.[/yellow]  "
            "Download it from https://github.com/LARC-CMU-SMU/FoodSeg103 "
            "and place it in either data/FoodSeg103/ or data/Images/ "
            "(expected subfolders: img_dir and ann_dir)."
        )
    else:
        console.print(f"[green]Dataset OK.[/green]  root: {FOODSEG103_ROOT}")


def check_finetuned_weights():
    sys.path.insert(0, str(BASE_DIR))
    from config import SEGMENTER_WEIGHTS
    path = Path(SEGMENTER_WEIGHTS)
    if (path / "config.json").exists():
        console.print(f"[green]Fine-tuned model found:[/green] {path}")
    else:
        console.print(
            "[yellow]Fine-tuned model not found.[/yellow]  "
            "Run: [bold]python train_foodseg103.py[/bold]"
        )


def seed_database():
    console.print("\nSeeding nutrition database from TKPI CSV…")
    sys.path.insert(0, str(BASE_DIR))
    from nutrition import NutritionDB
    db = NutritionDB()
    count = db.count()
    console.print(f"[green]Nutrition DB ready: {count} records[/green]")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="MBG Setup (FoodSeg103 edition)")
    parser.add_argument("--check", action="store_true", help="Only check environment")
    args = parser.parse_args()

    check_environment()
    if args.check:
        check_dataset()
        check_finetuned_weights()
        return

    download_encoder()
    check_dataset()
    check_finetuned_weights()
    seed_database()

    console.print("\n[bold green]Setup complete.[/bold green]")
    console.print("\nNext steps:")
    console.print("  1. Fine-tune: [bold]python train_foodseg103.py[/bold]")
    console.print("  2. Start API: [bold]uvicorn api:app --host 0.0.0.0 --port 8000[/bold]")
    console.print("  3. Start UI:  [bold]streamlit run app.py[/bold]")
    console.print("\nOr try the CLI:  [bold]python demo.py path/to/food.jpg[/bold]")


if __name__ == "__main__":
    main()
