"""
MBG Batch Processing Pipeline — segmentation edition.

Processes a folder of images and writes per-image JSON results
plus coloured overlay PNGs.

Usage:
    python batch_pipeline.py --input_dir ./images --output_dir ./results
    python batch_pipeline.py --input_dir ./images --output_dir ./results --no-overlay
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

from PIL import Image
from loguru import logger
from rich.console import Console
from rich.progress import (
    Progress, SpinnerColumn, TextColumn, BarColumn,
    MofNCompleteColumn, TimeRemainingColumn,
)

console = Console()
SUPPORTED_EXT = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def process_batch(input_dir: Path, output_dir: Path, save_overlay: bool):
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from pipeline import MBGPipeline

    image_paths = sorted(
        p for p in input_dir.rglob("*") if p.suffix.lower() in SUPPORTED_EXT
    )
    if not image_paths:
        console.print(f"[red]No supported images found in {input_dir}[/red]")
        sys.exit(1)

    console.print(f"\nFound {len(image_paths)} image(s) in {input_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)

    pipeline = MBGPipeline()
    if not pipeline.segmenter.is_finetuned:
        console.print(
            "[yellow]⚠  Fine-tuned weights not found — "
            "run train_foodseg103.py first for meaningful results.[/yellow]"
        )

    summary = []
    t_total = time.perf_counter()

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        MofNCompleteColumn(),
        TimeRemainingColumn(),
    ) as progress:
        task = progress.add_task("Processing…", total=len(image_paths))

        for img_path in image_paths:
            progress.update(task, description=img_path.name)
            try:
                image  = Image.open(img_path).convert("RGB")
                result = pipeline.run(image)

                # Drop non-serialisable PIL image / numpy mask from result
                result_json = {
                    "file":                str(img_path.name),
                    "total_items":         result["total_items"],
                    "processing_time_ms":  result["processing_time_ms"],
                    "items": [
                        {
                            k: (list(v) if k == "color" else v)
                            for k, v in item.items()
                            if k != "crop"        # no crop field in seg pipeline
                        }
                        for item in result["items"]
                    ],
                    "aggregate_nutrition": result["aggregate_nutrition"],
                }

                stem      = img_path.stem
                json_path = output_dir / f"{stem}_result.json"
                json_path.write_text(json.dumps(result_json, indent=2))

                if save_overlay:
                    overlay_path = output_dir / f"{stem}_overlay.png"
                    result["overlay"].convert("RGB").save(str(overlay_path))

                summary.append({
                    "file":   img_path.name,
                    "items":  result["total_items"],
                    "ms":     result["processing_time_ms"],
                })

            except Exception as e:
                logger.error(f"Failed on {img_path.name}: {e}")
                summary.append({"file": img_path.name, "items": 0, "ms": 0, "error": str(e)})

            progress.advance(task)

    elapsed = time.perf_counter() - t_total
    avg_ms  = sum(s["ms"] for s in summary) / max(len(summary), 1)

    console.print(f"\n[bold green]Batch complete[/bold green]")
    console.print(f"  Images processed : {len(summary)}")
    console.print(f"  Total time       : {elapsed:.1f}s")
    console.print(f"  Avg time/image   : {avg_ms:.0f}ms")
    console.print(f"  Results written  : {output_dir}")

    # Write summary CSV
    summary_path = output_dir / "batch_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2))
    console.print(f"  Summary          : {summary_path}")


def main():
    parser = argparse.ArgumentParser(description="MBG Batch Segmentation Pipeline")
    parser.add_argument("--input_dir",  required=True, help="Folder of input images")
    parser.add_argument("--output_dir", required=True, help="Folder for results")
    parser.add_argument("--no-overlay", action="store_true",
                        help="Skip saving overlay PNG files")
    args = parser.parse_args()

    process_batch(
        Path(args.input_dir),
        Path(args.output_dir),
        save_overlay=not args.no_overlay,
    )


if __name__ == "__main__":
    main()
