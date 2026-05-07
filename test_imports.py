#!/usr/bin/env python3
"""
Test script to verify all imports and core functionality.
Run: python test_imports.py
"""

import sys
from pathlib import Path

def test_imports():
    """Test all critical imports."""
    print("Testing imports...")
    try:
        import torch
        print("  torch:", torch.__version__)
    except ImportError as e:
        print(f"  ERROR: torch - {e}")
        return False

    try:
        import numpy as np
        print("  numpy:", np.__version__)
    except ImportError as e:
        print(f"  ERROR: numpy - {e}")
        return False

    try:
        from PIL import Image
        print("  PIL: OK")
    except ImportError as e:
        print(f"  ERROR: PIL - {e}")
        return False

    try:
        import transformers
        print("  transformers:", transformers.__version__)
    except ImportError as e:
        print(f"  ERROR: transformers - {e}")
        return False

    try:
        import fastapi
        print("  fastapi: OK")
    except ImportError as e:
        print(f"  ERROR: fastapi - {e}")
        return False

    try:
        import streamlit
        print("  streamlit: OK")
    except ImportError as e:
        print(f"  ERROR: streamlit - {e}")
        return False

    try:
        import plotly
        print("  plotly: OK")
    except ImportError as e:
        print(f"  ERROR: plotly - {e}")
        return False

    try:
        import loguru
        print("  loguru: OK")
    except ImportError as e:
        print(f"  ERROR: loguru - {e}")
        return False

    return True


def test_project_modules():
    """Test project-specific modules."""
    print("\nTesting project modules...")
    base_dir = Path(__file__).resolve().parent
    sys.path.insert(0, str(base_dir))

    try:
        from config import DEVICE, FOODSEG103_CLASSES, NUM_CLASSES, SEGMENTER_IMGSZ
        print(f"  config: OK ({NUM_CLASSES} classes, device={DEVICE})")
    except Exception as e:
        print(f"  ERROR: config - {e}")
        return False

    try:
        from nutrition import NutritionDB, NutritionService, aggregate_nutrition
        print("  nutrition: OK")
    except Exception as e:
        print(f"  ERROR: nutrition - {e}")
        return False

    try:
        from segmenter import FoodSegmenter
        print("  segmenter: OK")
    except Exception as e:
        print(f"  ERROR: segmenter - {e}")
        return False

    try:
        from pipeline import MBGPipeline, get_pipeline
        print("  pipeline: OK")
    except Exception as e:
        print(f"  ERROR: pipeline - {e}")
        return False

    return True


def test_config_consistency():
    """Verify configuration is internally consistent."""
    print("\nTesting configuration consistency...")
    from config import FOODSEG103_CLASSES, FOOD_HEIGHT_CM, NUM_CLASSES

    if len(FOODSEG103_CLASSES) != NUM_CLASSES:
        print(f"  ERROR: Class count mismatch: {len(FOODSEG103_CLASSES)} != {NUM_CLASSES}")
        return False

    if FOODSEG103_CLASSES[0] != "background":
        print("  ERROR: Class 0 should be 'background'")
        return False

    undefined_classes = []
    for cls_name in FOODSEG103_CLASSES[1:]:
        if cls_name not in FOOD_HEIGHT_CM and cls_name not in ["garlic", "other ingredients"]:
            undefined_classes.append(cls_name)

    if undefined_classes:
        print(f"  WARNING: {len(undefined_classes)} classes without height estimates:")
        for cls in undefined_classes[:5]:
            print(f"    - {cls}")
        if len(undefined_classes) > 5:
            print(f"    ... and {len(undefined_classes) - 5} more")

    print(f"  Configuration OK: {NUM_CLASSES} classes validated")
    return True


def main():
    """Run all tests."""
    print("=" * 60)
    print("MBG Project Validation Tests")
    print("=" * 60)

    all_pass = True

    if not test_imports():
        all_pass = False

    if not test_project_modules():
        all_pass = False

    if not test_config_consistency():
        all_pass = False

    print("\n" + "=" * 60)
    if all_pass:
        print("All tests PASSED")
        print("=" * 60)
        return 0
    else:
        print("Some tests FAILED")
        print("=" * 60)
        return 1


if __name__ == "__main__":
    sys.exit(main())
