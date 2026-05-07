"""
MBG CLI Demo — segmentation edition.
Tests the full pipeline without starting the API server.

Usage:
    python demo.py path/to/image.jpg
    python demo.py path/to/image.jpg --no-display
    python demo.py --url https://example.com/food.jpg
    python demo.py path/to/image.jpg --save-overlay overlay.png
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

import requests
from PIL import Image
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

console = Console()


def load_image(source: str) -> Image.Image:
    if source.startswith("http://") or source.startswith("https://"):
        console.print(f"Fetching image from URL: {source}")
        resp = requests.get(source, timeout=10)
        resp.raise_for_status()
        return Image.open(io.BytesIO(resp.content)).convert("RGB")
    path = Path(source)
    if not path.exists():
        console.print(f"[red]File not found: {source}[/red]")
        sys.exit(1)
    return Image.open(path).convert("RGB")


def print_nutrition(nut: dict, title: str = "Nutrition (per 100 g)"):
    fields = [
        ("Calories",      nut.get("calories"),       "kcal"),
        ("Protein",       nut.get("protein_g"),      "g"),
        ("Fat",           nut.get("fat_g"),          "g"),
        ("Carbohydrates", nut.get("carbohydrate_g"), "g"),
        ("Fiber",         nut.get("fiber_g"),        "g"),
        ("Sugar",         nut.get("sugar_g"),        "g"),
        ("Sodium",        nut.get("sodium_mg"),      "mg"),
    ]
    table = Table(title=title, show_header=True, header_style="bold cyan", min_width=44)
    table.add_column("Nutrient", style="dim")
    table.add_column("Value", justify="right")
    for label, val, unit in fields:
        display = f"{val:.1f} {unit}" if val is not None else "[dim]N/A[/dim]"
        table.add_row(label, display)
    console.print(table)
    console.print(f"  Source: [dim]{nut.get('source', 'unknown')}[/dim]")


def main():
    parser = argparse.ArgumentParser(description="MBG CLI Demo (segmentation)")
    parser.add_argument("image", nargs="?", help="Path to image file")
    parser.add_argument("--url",          help="Image URL (alternative to file path)")
    parser.add_argument("--no-display",   action="store_true",
                        help="Do not open the overlay image window")
    parser.add_argument("--save-overlay", metavar="PATH",
                        help="Save coloured segmentation overlay to this file")
    args = parser.parse_args()

    if not args.image and not args.url:
        parser.print_help()
        sys.exit(1)

    source = args.url if args.url else args.image

    sys.path.insert(0, str(Path(__file__).resolve().parent))

    console.print(Panel(
        "[bold]MBG – Meal-Based Nutrition Guide[/bold]\n"
        "FoodSeg103 Segmentation Demo",
        style="cyan",
    ))

    console.print("\nLoading pipeline…")
    from pipeline import MBGPipeline
    pipeline = MBGPipeline()

    if not pipeline.segmenter.is_finetuned:
        console.print(
            "[yellow]Warning: Fine-tuned weights not found.  "
            "Predictions will be random until you run train_foodseg103.py.[/yellow]\n"
        )

    image = load_image(source)
    console.print(f"Image size : {image.width}×{image.height} px\n")

    console.print("Running segmentation pipeline…")
    result = pipeline.run(image)

    console.print(
        f"\n[bold green]Done in {result['processing_time_ms']:.0f} ms[/bold green]"
    )
    console.print(f"Detected segments : {result['total_items']}\n")

    # ── Per-segment output ────────────────────────────────────────────────────
    for i, item in enumerate(result["items"]):
        label  = item["label"].title()
        conf   = item["confidence"]
        area   = item["area_cm2"]
        vol    = item["volume_cm3"]
        px     = item["pixel_count"]

        console.print(
            f"[bold]Segment {i+1}:[/bold] {label}  "
            f"(conf: {conf:.1%}  |  {px:,} px  |  "
            f"area ≈ {area:.1f} cm²  |  vol ≈ {vol:.1f} cm³)"
        )
        print_nutrition(item["nutrition"], title=f"Nutrition: {label}")
        console.print()

    # ── Aggregate ─────────────────────────────────────────────────────────────
    agg = result["aggregate_nutrition"]
    console.print(Panel("[bold]Aggregate Nutrition (total meal)[/bold]", style="magenta"))
    print_nutrition(agg, title="Total Meal")

    # ── Overlay ───────────────────────────────────────────────────────────────
    overlay = result["overlay"]

    if args.save_overlay:
        overlay.convert("RGB").save(args.save_overlay)
        console.print(f"\nOverlay saved to: [green]{args.save_overlay}[/green]")

    if not args.no_display:
        try:
            overlay.show()
        except Exception as e:
            console.print(f"[yellow]Could not display overlay image: {e}[/yellow]")


if __name__ == "__main__":
    main()
