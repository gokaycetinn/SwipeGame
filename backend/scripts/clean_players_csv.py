import argparse
from pathlib import Path
from typing import Optional

import pandas as pd


COLUMN_CANDIDATES = {
    "name": ["name", "short_name", "long_name", "player_name"],
    "nationality": ["nationality", "nationality_name", "nation"],
    "club": ["club", "club_name", "team", "team_name"],
    "position": ["position", "player_positions", "best_position", "pos"],
    "age": ["age"],
}


def pick_column(columns: list[str], candidates: list[str]) -> Optional[str]:
    lowered = {col.lower(): col for col in columns}
    for candidate in candidates:
        if candidate.lower() in lowered:
            return lowered[candidate.lower()]
    return None


def build_mapping(columns: list[str]) -> dict[str, str]:
    mapping: dict[str, str] = {}
    missing: list[str] = []

    for target, candidates in COLUMN_CANDIDATES.items():
        selected = pick_column(columns, candidates)
        if selected is None:
            missing.append(target)
        else:
            mapping[target] = selected

    if missing:
        raise ValueError(f"Missing required columns: {', '.join(missing)}")

    return mapping


def normalize_frame(df: pd.DataFrame, mapping: dict[str, str]) -> pd.DataFrame:
    selected = df[[mapping["name"], mapping["nationality"], mapping["club"], mapping["position"], mapping["age"]]].copy()
    selected.columns = ["name", "nationality", "club", "position", "age"]

    selected = selected.dropna(subset=["name", "nationality", "club", "position", "age"])
    selected["name"] = selected["name"].astype(str).str.strip()
    selected["nationality"] = selected["nationality"].astype(str).str.strip()
    selected["club"] = selected["club"].astype(str).str.strip()
    selected["position"] = selected["position"].astype(str).str.strip()
    selected["age"] = pd.to_numeric(selected["age"], errors="coerce")

    selected = selected.dropna(subset=["age"])
    selected["age"] = selected["age"].astype(int)

    selected = selected[(selected["age"] >= 14) & (selected["age"] <= 45)]
    selected = selected[selected["name"] != ""]
    selected = selected[selected["club"] != ""]

    selected = selected.drop_duplicates(subset=["name", "nationality", "club"], keep="first")
    selected = selected.reset_index(drop=True)
    return selected


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Clean raw football CSV into app-ready columns")
    parser.add_argument("--in", dest="input_path", required=True, help="Raw CSV path")
    parser.add_argument(
        "--out",
        default="backend/data/players_clean.csv",
        help="Output clean CSV path",
    )

    args = parser.parse_args()
    input_path = Path(args.input_path)
    output_path = Path(args.out)

    frame = pd.read_csv(input_path)
    mapping = build_mapping(list(frame.columns))
    cleaned = normalize_frame(frame, mapping)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    cleaned.to_csv(output_path, index=False)

    print(f"Input rows: {len(frame)}")
    print(f"Output rows: {len(cleaned)}")
    print(f"Saved: {output_path}")
