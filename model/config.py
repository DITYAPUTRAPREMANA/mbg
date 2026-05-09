"""
MBG Local Prototype — Configuration.

FoodSeg103-based semantic segmentation with volume estimation.
"""

from pathlib import Path

BASE_DIR   = Path(__file__).resolve().parent
DATA_DIR   = BASE_DIR / "data"
WEIGHTS_DIR = BASE_DIR / "weights"
DB_PATH    = DATA_DIR / "nutrition_cache.db"

DATA_DIR.mkdir(exist_ok=True)
WEIGHTS_DIR.mkdir(exist_ok=True)


def get_device() -> str:
    try:
        import torch
        return "cuda" if torch.cuda.is_available() else "cpu"
    except ImportError:
        return "cpu"


DEVICE = get_device()

# ── Segmentation model ────────────────────────────────────────────────────────
# Fine-tuned SegFormer-B2 on FoodSeg103.
# If the fine-tuned checkpoint doesn't exist, falls back to a pretrained
# SegFormer that has been adapted (weights replaced) for 104 classes.
SEGMENTER_WEIGHTS  = str(WEIGHTS_DIR / "foodseg103_segformer")   # HF-style directory
SEGMENTER_BASE_HF  = "nvidia/mit-b2"                             # encoder backbone
SEGMENTER_IMGSZ    = 512          # input resolution for SegFormer
SEGMENTER_CONF_THR = 0.45         # minimum confidence to keep a segment
MIN_SEGMENT_RATIO  = 0.005        # segments < 0.5 % of image area are dropped

# ── Volume estimation ─────────────────────────────────────────────────────────
# Calibration: 30 pixels = 1 cm  →  30² pixels = 1 cm²
PIXELS_PER_CM  = 30
PIXELS_PER_CM2 = PIXELS_PER_CM ** 2   # 900 px² == 1 cm²

# Per-category estimated height (depth) in centimetres.
# Used to convert projected 2-D area → approximate 3-D volume.
FOOD_HEIGHT_CM: dict[str, float] = {
    # drinks / liquids
    "wine": 8.0, "milkshake": 12.0, "coffee": 8.0, "juice": 10.0,
    "milk": 10.0, "tea": 8.0, "soup": 6.0,
    # baked / flat
    "bread": 5.0, "pizza": 2.5, "pie": 5.0, "cake": 8.0,
    "hanamaki baozi": 5.0, "wonton dumplings": 3.0,
    "french fries": 4.0, "biscuit": 1.5, "popcorn": 6.0,
    "hamburg": 10.0, "pasta": 3.0, "noodles": 3.0, "rice": 4.0,
    "corn": 15.0, "garlic bread": 3.0, "egg tart": 4.0,
    # desserts
    "candy": 2.0, "chocolate": 2.0, "pudding": 5.0, "ice cream": 6.0,
    "macarons": 3.0, "baklava": 4.0,
    # dairy / spreads
    "cheese butter": 2.0,
    # round / large fruits
    "apple": 7.0, "orange": 7.0, "mango": 8.0, "peach": 7.0,
    "pear": 8.0, "fig": 5.0, "kiwi": 5.0, "melon": 10.0,
    "watermelon": 12.0, "pineapple": 20.0, "avocado": 8.0,
    "lemon": 5.0, "banana": 3.0, "grape": 2.5,
    # small fruits
    "strawberry": 3.0, "cherry": 2.5, "blueberry": 1.5,
    "raspberry": 1.5, "apricot": 4.0, "date": 3.0,
    # olives
    "olives": 2.0,
    # nuts / seeds
    "almond": 1.5, "cashew": 1.5, "walnut": 2.0, "peanut": 1.5,
    "red beans": 1.0, "dried cranberries": 1.0, "soy": 1.0,
    # proteins
    "steak": 3.0, "pork": 3.0, "chicken duck": 4.0, "sausage": 3.0,
    "fried meat": 3.0, "lamb": 3.0, "crab": 5.0, "fish": 3.0,
    "shellfish": 3.0, "shrimp": 2.0, "egg": 4.0,
    # sauce
    "sauce": 1.0,
    # tofu / legumes
    "tofu": 4.0,
    # vegetables
    "eggplant": 6.0, "potato": 5.0, "cauliflower": 8.0,
    "tomato": 6.0, "kelp": 1.0, "seaweed": 0.5,
    "spring onion": 20.0, "rape": 10.0, "ginger": 4.0, "garlic": 4.0,
    "okra": 8.0, "lettuce": 10.0, "pumpkin": 12.0,
    "cucumber": 20.0, "white radish": 20.0, "carrot": 15.0,
    "asparagus": 20.0, "bamboo shoots": 10.0, "broccoli": 8.0,
    "celery stick": 30.0, "cilantro mint": 10.0, "snow peas": 5.0,
    "cabbage": 12.0, "bean sprouts": 5.0, "onion": 5.0,
    "pepper": 8.0, "green beans": 10.0, "French beans": 10.0,
    # mushrooms
    "king oyster mushroom": 10.0, "shiitake": 3.0,
    "enoki mushroom": 10.0, "oyster mushroom": 5.0,
    "white button mushroom": 4.0,
    # mixed
    "salad": 5.0, "other ingredients": 3.0,
}
DEFAULT_FOOD_HEIGHT_CM = 3.0  # fallback for unlisted items

# ── FoodSeg103 class list (index → name) ──────────────────────────────────────
FOODSEG103_CLASSES: list[str] = [
    "background",            # 0
    "candy",                 # 1
    "egg tart",              # 2
    "french fries",          # 3
    "chocolate",             # 4
    "biscuit",               # 5
    "popcorn",               # 6
    "pudding",               # 7
    "ice cream",             # 8
    "cheese butter",         # 9
    "cake",                  # 10
    "wine",                  # 11
    "milkshake",             # 12
    "coffee",                # 13
    "juice",                 # 14
    "milk",                  # 15
    "tea",                   # 16
    "almond",                # 17
    "red beans",             # 18
    "cashew",                # 19
    "dried cranberries",     # 20
    "soy",                   # 21
    "walnut",                # 22
    "peanut",                # 23
    "egg",                   # 24
    "apple",                 # 25
    "date",                  # 26
    "apricot",               # 27
    "avocado",               # 28
    "banana",                # 29
    "strawberry",            # 30
    "cherry",                # 31
    "blueberry",             # 32
    "raspberry",             # 33
    "mango",                 # 34
    "olives",                # 35
    "peach",                 # 36
    "lemon",                 # 37
    "pear",                  # 38
    "fig",                   # 39
    "pineapple",             # 40
    "grape",                 # 41
    "kiwi",                  # 42
    "melon",                 # 43
    "orange",                # 44
    "watermelon",            # 45
    "steak",                 # 46
    "pork",                  # 47
    "chicken duck",          # 48
    "sausage",               # 49
    "fried meat",            # 50
    "lamb",                  # 51
    "sauce",                 # 52
    "crab",                  # 53
    "fish",                  # 54
    "shellfish",             # 55
    "shrimp",                # 56
    "soup",                  # 57
    "bread",                 # 58
    "corn",                  # 59
    "hamburg",               # 60
    "pizza",                 # 61
    "hanamaki baozi",        # 62
    "wonton dumplings",      # 63
    "pasta",                 # 64
    "noodles",               # 65
    "rice",                  # 66
    "pie",                   # 67
    "tofu",                  # 68
    "eggplant",              # 69
    "potato",                # 70
    "garlic",                # 71
    "cauliflower",           # 72
    "tomato",                # 73
    "kelp",                  # 74
    "seaweed",               # 75
    "spring onion",          # 76
    "rape",                  # 77
    "ginger",                # 78
    "okra",                  # 79
    "lettuce",               # 80
    "pumpkin",               # 81
    "cucumber",              # 82
    "white radish",          # 83
    "carrot",                # 84
    "asparagus",             # 85
    "bamboo shoots",         # 86
    "broccoli",              # 87
    "celery stick",          # 88
    "cilantro mint",         # 89
    "snow peas",             # 90
    "cabbage",               # 91
    "bean sprouts",          # 92
    "onion",                 # 93
    "pepper",                # 94
    "green beans",           # 95
    "French beans",          # 96
    "king oyster mushroom",  # 97
    "shiitake",              # 98
    "enoki mushroom",        # 99
    "oyster mushroom",       # 100
    "white button mushroom", # 101
    "salad",                 # 102
    "other ingredients",     # 103
]

NUM_CLASSES = len(FOODSEG103_CLASSES)  # 104 (including background)

# ── Dataset paths (user has already downloaded FoodSeg103) ────────────────────
# Supported layouts:
#   1) data/FoodSeg103/img_dir/* and ann_dir/*
#   2) data/Images/img_dir/* and ann_dir/*
def _resolve_foodseg103_root() -> Path:
    candidates = [
        DATA_DIR / "FoodSeg103",
        DATA_DIR / "Images",
    ]
    for root in candidates:
        if (root / "img_dir").exists() and (root / "ann_dir").exists():
            return root
    return candidates[0]


FOODSEG103_ROOT = _resolve_foodseg103_root()
FOODSEG103_IMG_TRAIN = FOODSEG103_ROOT / "img_dir" / "train"
FOODSEG103_IMG_TEST  = FOODSEG103_ROOT / "img_dir" / "test"
FOODSEG103_ANN_TRAIN = FOODSEG103_ROOT / "ann_dir" / "train"
FOODSEG103_ANN_TEST  = FOODSEG103_ROOT / "ann_dir" / "test"

# ── Nutrition / API ──────────────────────────────────────────────────────────
OFF_API_BASE       = "https://world.openfoodfacts.org/cgi/search.pl"
OFF_PRODUCT_URL    = "https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
LOCAL_NUTRITION_CSV = DATA_DIR / "tkpi_2020_english (1).csv"
OFF_TIMEOUT        = 6
API_TIMEOUT        = 30
