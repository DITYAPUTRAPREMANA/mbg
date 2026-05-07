"""
MBG Local Prototype — Streamlit UI (FoodSeg103 segmentation edition).

Run:
    streamlit run app.py
"""

import io
import os
import sys
from pathlib import Path
from typing import Optional

import requests
import streamlit as st
import plotly.graph_objects as go
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

API_BASE = os.getenv("API_URL", "http://localhost:8000")

st.set_page_config(
    page_title="MBG – Meal-Based Nutrition Guide",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.markdown("""
<style>
    .seg-card {
        background: #1e1e2e;
        border-radius: 10px;
        padding: 14px 16px;
        margin: 6px 0;
        border-left: 4px solid #7c6af7;
    }
    .metric-row {
        display: flex;
        justify-content: space-between;
        margin: 3px 0;
        font-size: 13px;
    }
    .metric-label { color: #a0a0b0; }
    .metric-value { color: #e0e0ff; font-weight: 600; }
    .vol-badge {
        background: #2a2a3e;
        border-radius: 6px;
        padding: 2px 8px;
        font-size: 12px;
        color: #96CEB4;
        margin-left: 6px;
    }
</style>
""", unsafe_allow_html=True)


# ── API helpers ───────────────────────────────────────────────────────────────

def api_health() -> dict:
    try:
        r = requests.get(f"{API_BASE}/health", timeout=3)
        return r.json() if r.ok else {}
    except Exception:
        return {}


def api_analyze(image_bytes: bytes, filename: str) -> Optional[dict]:
    try:
        files = {"file": (filename, io.BytesIO(image_bytes), "image/jpeg")}
        r = requests.post(f"{API_BASE}/analyze/", files=files, timeout=90)
        if r.ok:
            return r.json()
        st.error(f"API error {r.status_code}: {r.json().get('detail', 'Unknown error')}")
    except requests.ConnectionError:
        st.error(
            "Cannot connect to MBG API.  "
            "Make sure `uvicorn api:app --port 8000` is running."
        )
    except Exception as e:
        st.error(f"Request failed: {e}")
    return None


def api_overlay(image_bytes: bytes, filename: str) -> Optional[bytes]:
    """Fetch the segmentation overlay image from the API."""
    try:
        files = {"file": (filename, io.BytesIO(image_bytes), "image/jpeg")}
        r = requests.post(f"{API_BASE}/analyze/overlay", files=files, timeout=90)
        if r.ok:
            return r.content
    except Exception:
        pass
    return None


def api_search(query: str, limit: int = 10) -> list:
    try:
        r = requests.get(
            f"{API_BASE}/nutrition/search",
            params={"q": query, "limit": limit},
            timeout=5,
        )
        if r.ok:
            return r.json().get("results", [])
    except Exception:
        pass
    return []


# ── Rendering helpers ─────────────────────────────────────────────────────────

def render_nutrition_card(nut: dict, title: str = "Nutrition (per 100 g)"):
    fields = [
        ("Calories",       nut.get("calories"),       "kcal"),
        ("Protein",        nut.get("protein_g"),      "g"),
        ("Fat",            nut.get("fat_g"),          "g"),
        ("Carbohydrates",  nut.get("carbohydrate_g"), "g"),
        ("Fiber",          nut.get("fiber_g"),        "g"),
        ("Sugar",          nut.get("sugar_g"),        "g"),
        ("Sodium",         nut.get("sodium_mg"),      "mg"),
    ]
    rows_html = "".join(
        f'<div class="metric-row">'
        f'<span class="metric-label">{lbl}</span>'
        f'<span class="metric-value">'
        f'{f"{val:.1f} {unit}" if val is not None else "N/A"}'
        f'</span></div>'
        for lbl, val, unit in fields
    )
    source = nut.get("source", "")
    st.markdown(f"""
    <div class="seg-card">
        <strong>{title}</strong>
        <small style="color:#888; margin-left:8px;">Source: {source}</small>
        {rows_html}
    </div>
    """, unsafe_allow_html=True)


def render_volume_card(item: dict):
    color  = item.get("color", [124, 106, 247])
    hex_c  = "#{:02x}{:02x}{:02x}".format(*color)
    label  = item["label"].title()
    area   = item.get("area_cm2", 0)
    vol    = item.get("volume_cm3", 0)
    px     = item.get("pixel_count", 0)
    conf   = item.get("confidence", 0)
    st.markdown(f"""
    <div class="seg-card" style="border-left-color:{hex_c};">
        <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:14px;height:14px;border-radius:3px;
                        background:{hex_c};flex-shrink:0;"></div>
            <strong>{label}</strong>
            <span class="vol-badge">≈ {vol:.1f} cm³</span>
        </div>
        <div class="metric-row" style="margin-top:6px;">
            <span class="metric-label">Projected area</span>
            <span class="metric-value">{area:.1f} cm²</span>
        </div>
        <div class="metric-row">
            <span class="metric-label">Pixel coverage</span>
            <span class="metric-value">{px:,} px</span>
        </div>
        <div class="metric-row">
            <span class="metric-label">Confidence</span>
            <span class="metric-value">{conf:.1%}</span>
        </div>
    </div>
    """, unsafe_allow_html=True)


def render_macro_chart(agg: dict):
    macros = {
        "Protein":       agg.get("protein_g") or 0,
        "Fat":           agg.get("fat_g") or 0,
        "Carbohydrates": agg.get("carbohydrate_g") or 0,
        "Fiber":         agg.get("fiber_g") or 0,
    }
    if sum(macros.values()) == 0:
        st.info("No macro data available.")
        return
    fig = go.Figure(go.Pie(
        labels=list(macros.keys()),
        values=list(macros.values()),
        hole=0.45,
        marker=dict(colors=["#7C6AF7", "#FF6B6B", "#4ECDC4", "#96CEB4"]),
        textinfo="label+percent",
        hovertemplate="%{label}: %{value:.1f}g<extra></extra>",
    ))
    fig.update_layout(
        title="Macro Distribution",
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(color="#e0e0ff"),
        margin=dict(t=40, b=0, l=0, r=0),
        height=280,
    )
    st.plotly_chart(fig, use_container_width=True)


def render_calorie_bar(agg: dict):
    cals = agg.get("calories")
    if cals is None:
        return
    dri = 2000
    fig = go.Figure(go.Bar(
        x=[cals], y=["Meal"], orientation="h",
        marker=dict(color="#7C6AF7"),
        text=[f"{cals:.0f} kcal  ({cals/dri*100:.0f}% of {dri} kcal DRI)"],
        textposition="auto",
    ))
    fig.update_layout(
        title="Total Calories",
        xaxis=dict(range=[0, max(dri, cals * 1.1)], showgrid=False),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(color="#e0e0ff"),
        height=90,
        margin=dict(t=30, b=0, l=0, r=0),
    )
    st.plotly_chart(fig, use_container_width=True)


def render_volume_chart(items: list):
    """Bar chart of estimated volume per food segment."""
    if not items:
        return
    labels  = [it["label"].title() for it in items]
    volumes = [it.get("volume_cm3", 0) for it in items]
    colors  = [
        "#{:02x}{:02x}{:02x}".format(*it.get("color", [124, 106, 247]))
        for it in items
    ]
    fig = go.Figure(go.Bar(
        x=labels, y=volumes,
        marker=dict(color=colors),
        text=[f"{v:.1f}" for v in volumes],
        textposition="outside",
        hovertemplate="%{x}: %{y:.1f} cm³<extra></extra>",
    ))
    fig.update_layout(
        title="Estimated Volume per Ingredient (cm³)",
        yaxis=dict(title="cm³"),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(color="#e0e0ff"),
        margin=dict(t=40, b=60, l=0, r=0),
        height=300,
    )
    st.plotly_chart(fig, use_container_width=True)


def render_legend(items: list):
    """Small coloured legend chips for each segment."""
    chips = "".join(
        f'<span style="display:inline-flex;align-items:center;gap:5px;'
        f'background:#1e1e2e;border-radius:6px;padding:3px 9px;margin:3px;">'
        f'<span style="width:10px;height:10px;border-radius:2px;'
        f'background:#{"{:02x}{:02x}{:02x}".format(*it["color"])};"></span>'
        f'{it["label"].title()}'
        f'</span>'
        for it in items
    )
    st.markdown(chips, unsafe_allow_html=True)


# ── Sidebar ───────────────────────────────────────────────────────────────────

with st.sidebar:
    st.title("MBG")
    st.caption("Meal-Based Nutrition Guide — FoodSeg103 Edition")
    st.divider()

    health = api_health()
    if health.get("status") == "ok":
        st.success("API Online")
        st.caption(f"Device: {health.get('device', '?').upper()}")
        st.caption(f"Nutrition DB: {health.get('db_size', 0):,} records")
        if health.get("model_ready"):
            st.caption("Fine-tuned model loaded")
        else:
            st.warning("Base model only — run train_foodseg103.py")
    else:
        st.error("API Offline")
        st.caption("Run: `uvicorn api:app --port 8000`")

    st.divider()
    st.caption("Volume calibration: 30 px = 1 cm")

    page = st.radio("Navigation", ["Analyze Image", "Search Nutrition", "About"])
    st.divider()
    st.caption("AMD Developer Hackathon 2025")


# ── Pages ─────────────────────────────────────────────────────────────────────

if page == "Analyze Image":
    st.title("Food Segmentation & Nutrition Analysis")
    st.write(
        "Upload a food photo.  The model segments every ingredient, "
        "estimates its volume, and looks up nutrition data."
    )

    col_left, col_right = st.columns([1, 1], gap="large")

    with col_left:
        uploaded    = st.file_uploader("Upload image", type=["jpg", "jpeg", "png", "webp"])
        use_url     = st.checkbox("Or enter image URL")
        image_url   = st.text_input("Image URL", placeholder="https://...") if use_url else None
        analyze_btn = st.button("Analyze", type="primary", use_container_width=True)

    if analyze_btn:
        image_bytes, filename = None, "image.jpg"

        if uploaded:
            image_bytes = uploaded.read()
            filename    = uploaded.name
        elif image_url:
            try:
                r = requests.get(image_url, timeout=10)
                r.raise_for_status()
                image_bytes = r.content
                filename    = "from_url.jpg"
            except Exception as e:
                st.error(f"Failed to load URL: {e}")

        if image_bytes:
            with st.spinner("Segmenting image and looking up nutrition…"):
                result        = api_analyze(image_bytes, filename)
                overlay_bytes = api_overlay(image_bytes, filename)

            if result:
                items = result.get("items", [])
                agg   = result.get("aggregate_nutrition", {})

                with col_left:
                    if overlay_bytes:
                        overlay_img = Image.open(io.BytesIO(overlay_bytes))
                        st.image(overlay_img, caption="Segmentation overlay", use_container_width=True)
                    else:
                        original = Image.open(io.BytesIO(image_bytes))
                        st.image(original, caption="Original image", use_container_width=True)

                    st.caption(
                        f"Found **{result.get('total_items', 0)}** ingredient(s) "
                        f"in **{result.get('processing_time_ms', 0):.0f} ms**"
                    )

                    st.subheader("Segment Legend")
                    render_legend(items)

                with col_right:
                    st.subheader("Aggregate Nutrition")
                    render_calorie_bar(agg)
                    render_macro_chart(agg)
                    render_nutrition_card(agg, title="Total for this meal")

                    st.subheader("Volume Estimates")
                    render_volume_chart(items)

                    st.subheader(f"Detected Ingredients ({len(items)})")
                    for i, item in enumerate(items):
                        label = item["label"].title()
                        vol   = item.get("volume_cm3", 0)
                        conf  = item.get("confidence", 0)
                        with st.expander(
                            f"{i+1}. {label}  —  {vol:.1f} cm³  ({conf:.0%})",
                            expanded=i == 0,
                        ):
                            render_volume_card(item)
                            render_nutrition_card(
                                item.get("nutrition", {}),
                                title=f"Nutrition: {label}",
                            )

elif page == "Search Nutrition":
    st.title("Nutrition Database Search")
    st.write(
        "Search the local nutrition database.  "
        "Covers all 103 FoodSeg103 ingredient categories plus Indonesian foods."
    )

    query = st.text_input(
        "Search food",
        placeholder="e.g., rice, chicken duck, broccoli, nasi goreng",
    )
    limit = st.slider("Max results", 1, 50, 10)

    if st.button("Search", type="primary") and query:
        with st.spinner("Searching…"):
            results = api_search(query, limit)
        if results:
            st.success(f"Found {len(results)} result(s)")
            for r in results:
                with st.expander(r.get("food_name", "Unknown").title()):
                    render_nutrition_card(r)
        else:
            st.info("No results found. Try a different keyword.")

elif page == "About":
    st.title("About MBG")
    st.markdown("""
**MBG (Meal-Based Nutrition Guide)** is an AI-powered food segmentation and
nutrition analysis system built for the AMD Developer Hackathon 2025.

---

### How it works

1. **Upload** a photo of raw ingredients or a prepared meal.
2. **SegFormer** (fine-tuned on FoodSeg103) produces a pixel-level segmentation
   mask across 103 food categories.
3. **Volume estimation** converts each segment's pixel area to cm² using the
   calibration factor **30 px = 1 cm**, then multiplies by a per-category
   depth estimate to approximate volume in cm³.
4. **Nutrition lookup** maps each category to per-100 g nutritional data from
   the local SQLite database (seeded from CSV) or Open Food Facts API.
5. Results are visualised as a coloured overlay, per-segment volume chart,
   and a nutrition breakdown.

---

### Dataset

**FoodSeg103** — 7,118 images, 103 ingredient categories, pixel-wise masks.
Curated from Recipe1M and annotated by human annotators.

| Split | Images |
|-------|--------|
| Train | 4,983  |
| Test  | 2,135  |

---

### Stack

| Component        | Technology |
|------------------|------------|
| Segmentation     | SegFormer-B2 (HuggingFace Transformers) |
| Fine-tuning      | PyTorch + AdamW, FoodSeg103 |
| Volume estimate  | Pixel-area × depth heuristic (30 px/cm) |
| Nutrition DB     | SQLite + Open Food Facts |
| Backend          | FastAPI + uvicorn |
| Frontend         | Streamlit + Plotly |

---

### Target Hardware

- AMD Instinct MI300X (AMD Developer Cloud)
- Local dev: AMD Ryzen 7 8845HS / 16 GB RAM / 6 GB VRAM (NVIDIA RTX 4050)

---

**AMD Developer Hackathon 2025** — Track 1 (AI Agents) · Track 3 (Vision & Multimodal AI)
    """)
