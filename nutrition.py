"""
Nutrition lookup service.

Priority chain:
  1. In-memory cache (fastest)
  2. SQLite cache (local disk, persisted)
  3. Local CSV (bundled dataset)
  4. Open Food Facts API (free, no key)
"""

from __future__ import annotations

import csv
import sqlite3
from pathlib import Path
from typing import Optional
from difflib import get_close_matches

import requests
from loguru import logger

from config import (
    DB_PATH, LOCAL_NUTRITION_CSV, OFF_API_BASE, OFF_TIMEOUT
)

EMPTY_NUTRITION = {
    "food_name":      None,
    "calories":       None,
    "protein_g":      None,
    "fat_g":          None,
    "carbohydrate_g": None,
    "fiber_g":        None,
    "sugar_g":        None,
    "sodium_mg":      None,
    "source":         "not_found",
}

NUMERIC_FIELDS = [
    "calories", "protein_g", "fat_g",
    "carbohydrate_g", "fiber_g", "sugar_g", "sodium_mg",
]


class NutritionDB:
    """SQLite-backed nutrition cache with local CSV seeding."""

    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self._conn: Optional[sqlite3.Connection] = None
        self._init_db()
        self._seed_from_csv()

    def _connect(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def _init_db(self):
        conn = self._connect()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS nutrition (
                id             INTEGER PRIMARY KEY AUTOINCREMENT,
                food_name      TEXT NOT NULL,
                name_lower     TEXT NOT NULL,
                calories       REAL,
                protein_g      REAL,
                fat_g          REAL,
                carbohydrate_g REAL,
                fiber_g        REAL,
                sugar_g        REAL,
                sodium_mg      REAL,
                source         TEXT,
                created_at     INTEGER DEFAULT (strftime('%s','now'))
            )
        """)
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_name_lower ON nutrition(name_lower)"
        )
        conn.commit()

    def _seed_from_csv(self):
        if not LOCAL_NUTRITION_CSV.exists():
            return
        conn = self._connect()
        existing_names = {
            r[0]
            for r in conn.execute("SELECT name_lower FROM nutrition").fetchall()
            if r[0]
        }

        rows_inserted = 0
        rows_updated = 0
        with open(LOCAL_NUTRITION_CSV, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                food_name = (row.get("food_name") or row.get("name") or "").strip()
                if not food_name:
                    continue

                name_lower = food_name.lower()
                calories = _to_float(row.get("calories") or row.get("energy_kcal"))
                protein = _to_float(row.get("protein_g"))
                fat = _to_float(row.get("fat_g"))
                carbohydrate = _to_float(row.get("carbohydrate_g") or row.get("carb_g"))
                fiber = _to_float(row.get("fiber_g"))
                sugar = _to_float(row.get("sugar_g"))
                sodium = _to_float(row.get("sodium_mg"))
                source = row.get("source", "local_csv")

                if name_lower in existing_names:
                    conn.execute("""
                        UPDATE nutrition
                        SET food_name = ?,
                            calories = ?,
                            protein_g = ?,
                            fat_g = ?,
                            carbohydrate_g = ?,
                            fiber_g = ?,
                            sugar_g = ?,
                            sodium_mg = ?,
                            source = ?
                        WHERE name_lower = ?
                    """, (
                        food_name,
                        calories,
                        protein,
                        fat,
                        carbohydrate,
                        fiber,
                        sugar,
                        sodium,
                        source,
                        name_lower,
                    ))
                    rows_updated += 1
                    continue

                conn.execute("""
                    INSERT OR IGNORE INTO nutrition
                    (food_name, name_lower, calories, protein_g, fat_g,
                     carbohydrate_g, fiber_g, sugar_g, sodium_mg, source)
                    VALUES (?,?,?,?,?,?,?,?,?,?)
                """, (
                    food_name,
                    name_lower,
                    calories,
                    protein,
                    fat,
                    carbohydrate,
                    fiber,
                    sugar,
                    sodium,
                    source,
                ))
                existing_names.add(name_lower)
                rows_inserted += 1
        conn.commit()
        logger.info(
            f"Seeded nutrition DB from {LOCAL_NUTRITION_CSV.name}: "
            f"{rows_inserted} inserted, {rows_updated} updated."
        )

    def lookup(self, food_name: str) -> Optional[dict]:
        key = food_name.strip().lower()
        conn = self._connect()

        # 1. Exact match
        row = conn.execute(
            "SELECT * FROM nutrition WHERE name_lower = ? LIMIT 1", (key,)
        ).fetchone()
        if row:
            return dict(row)

        # 2. Substring match
        row = conn.execute(
            "SELECT * FROM nutrition WHERE name_lower LIKE ? LIMIT 1",
            (f"%{key}%",)
        ).fetchone()
        if row:
            return dict(row)

        # 3. Fuzzy match
        all_names = [
            r[0] for r in conn.execute(
                "SELECT name_lower FROM nutrition"
            ).fetchall()
        ]
        matches = get_close_matches(key, all_names, n=1, cutoff=0.70)
        if matches:
            row = conn.execute(
                "SELECT * FROM nutrition WHERE name_lower = ? LIMIT 1",
                (matches[0],)
            ).fetchone()
            if row:
                return dict(row)

        return None

    def save(self, data: dict):
        conn = self._connect()
        name = data.get("food_name", "unknown")
        conn.execute("""
            INSERT OR REPLACE INTO nutrition
            (food_name, name_lower, calories, protein_g, fat_g,
             carbohydrate_g, fiber_g, sugar_g, sodium_mg, source)
            VALUES (?,?,?,?,?,?,?,?,?,?)
        """, (
            name, name.strip().lower(),
            data.get("calories"),    data.get("protein_g"),
            data.get("fat_g"),       data.get("carbohydrate_g"),
            data.get("fiber_g"),     data.get("sugar_g"),
            data.get("sodium_mg"),   data.get("source", "api"),
        ))
        conn.commit()

    def search(self, query: str, limit: int = 10) -> list[dict]:
        conn = self._connect()
        rows = conn.execute(
            "SELECT * FROM nutrition WHERE name_lower LIKE ? LIMIT ?",
            (f"%{query.lower()}%", limit),
        ).fetchall()
        return [dict(r) for r in rows]

    def count(self) -> int:
        return self._connect().execute(
            "SELECT COUNT(*) FROM nutrition"
        ).fetchone()[0]


class NutritionService:
    """High-level nutrition lookup with in-memory cache and API fallback."""

    def __init__(self, db: NutritionDB):
        self.db = db
        self._mem: dict[str, dict] = {}

    def lookup(self, food_name: str) -> dict:
        key = food_name.strip().lower()

        if key in self._mem:
            return self._mem[key]

        # 1. Local DB / CSV
        result = self.db.lookup(food_name)
        if result:
            self._mem[key] = _row_to_nutrition(result, food_name)
            return self._mem[key]

        # 2. Open Food Facts
        result = _query_off(food_name)
        if result:
            result["food_name"] = food_name
            self.db.save(result)
            self._mem[key] = result
            return result

        empty = dict(EMPTY_NUTRITION)
        empty["food_name"] = food_name
        return empty

    def search(self, query: str, limit: int = 10) -> list[dict]:
        return self.db.search(query, limit)


# ── helpers ──────────────────────────────────────────────────────────────────

def _to_float(val) -> Optional[float]:
    try:
        return float(val) if val not in (None, "", "N/A") else None
    except (TypeError, ValueError):
        return None


def _row_to_nutrition(row: dict, food_name: str) -> dict:
    return {
        "food_name":      row.get("food_name", food_name),
        "calories":       row.get("calories"),
        "protein_g":      row.get("protein_g"),
        "fat_g":          row.get("fat_g"),
        "carbohydrate_g": row.get("carbohydrate_g"),
        "fiber_g":        row.get("fiber_g"),
        "sugar_g":        row.get("sugar_g"),
        "sodium_mg":      row.get("sodium_mg"),
        "source":         row.get("source", "local"),
    }


def _query_off(search_term: str) -> Optional[dict]:
    """Query Open Food Facts and return normalised nutrition dict."""
    try:
        params = {
            "search_terms": search_term,
            "search_simple": 1,
            "action": "process",
            "json": 1,
            "page_size": 3,
            "fields": "product_name,nutriments",
        }
        resp = requests.get(OFF_API_BASE, params=params, timeout=OFF_TIMEOUT)
        if resp.status_code != 200:
            return None

        for product in resp.json().get("products", []):
            nut = product.get("nutriments", {})
            calories = _to_float(
                nut.get("energy-kcal_100g") or nut.get("energy_100g")
            )
            if calories is None:
                continue
            sodium_raw = _to_float(nut.get("sodium_100g"))
            return {
                "food_name":      product.get("product_name", search_term),
                "calories":       calories,
                "protein_g":      _to_float(nut.get("proteins_100g")),
                "fat_g":          _to_float(nut.get("fat_100g")),
                "carbohydrate_g": _to_float(nut.get("carbohydrates_100g")),
                "fiber_g":        _to_float(nut.get("fiber_100g")),
                "sugar_g":        _to_float(nut.get("sugars_100g")),
                "sodium_mg":      sodium_raw * 1000 if sodium_raw is not None else None,
                "source":         "Open Food Facts",
            }
    except Exception as e:
        logger.warning(f"OFF API error for '{search_term}': {e}")
    return None


def aggregate_nutrition(nutrition_list: list[dict]) -> dict:
    """Sum numeric nutrition fields across all items."""
    totals    = {f: 0.0 for f in NUMERIC_FIELDS}
    found_any = False
    sources   = set()
    for nut in nutrition_list:
        if nut.get("source"):
            sources.add(nut.get("source"))
        for field in NUMERIC_FIELDS:
            val = nut.get(field)
            if val is not None:
                totals[field] += float(val)
                found_any = True
    if not found_any:
        result = {k: None for k in NUMERIC_FIELDS}
        result["source"] = "not_found"
        return result
    result = {k: round(v, 2) for k, v in totals.items()}
    result["source"] = ", ".join(sorted(sources)) if sources else "aggregated"
    return result
