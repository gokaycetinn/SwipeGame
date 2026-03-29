import argparse
import time
from pathlib import Path
from urllib.parse import quote

import pandas as pd
import requests

WIKIPEDIA_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
WIKIMEDIA_SEARCH_API = "https://commons.wikimedia.org/w/api.php"


def get_wikipedia_thumbnail(name: str) -> str | None:
    title = quote(name.replace(" ", "_"))
    url = WIKIPEDIA_SUMMARY_API.format(title=title)

    try:
        response = requests.get(url, timeout=15)
        if response.status_code != 200:
            return None
        payload = response.json()
        if "thumbnail" in payload:
            return payload["thumbnail"].get("source")
    except Exception:
        return None

    return None


def get_wikimedia_image(name: str) -> str | None:
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": f"{name} footballer",
        "gsrnamespace": 6,
        "gsrlimit": 1,
        "prop": "imageinfo",
        "iiprop": "url",
    }

    try:
        response = requests.get(WIKIMEDIA_SEARCH_API, params=params, timeout=20)
        if response.status_code != 200:
            return None
        payload = response.json()
        pages = payload.get("query", {}).get("pages", {})
        for page in pages.values():
            infos = page.get("imageinfo") or []
            if infos:
                return infos[0].get("url")
    except Exception:
        return None

    return None


def get_player_image(name: str) -> str | None:
    image = get_wikipedia_thumbnail(name)
    if image:
        return image
    return get_wikimedia_image(name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add image_url to cleaned player CSV")
    parser.add_argument(
        "--in",
        dest="input_path",
        default="backend/data/players_clean.csv",
        help="Input cleaned CSV path",
    )
    parser.add_argument(
        "--out",
        default="backend/data/players_enriched.csv",
        help="Output enriched CSV path",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only enrich first N rows (0 = all)",
    )
    parser.add_argument(
        "--sleep",
        type=float,
        default=0.15,
        help="Sleep between requests to avoid rate limit",
    )

    args = parser.parse_args()

    input_path = Path(args.input_path)
    output_path = Path(args.out)

    frame = pd.read_csv(input_path)
    if "image_url" not in frame.columns:
        frame["image_url"] = ""

    total = len(frame) if args.limit <= 0 else min(args.limit, len(frame))

    for idx in range(total):
        row = frame.iloc[idx]
        if str(row.get("image_url", "")).strip():
            continue

        name = str(row["name"]).strip()
        if not name:
            continue

        image_url = get_player_image(name)
        if image_url:
            frame.at[idx, "image_url"] = image_url

        time.sleep(max(args.sleep, 0.0))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    frame.to_csv(output_path, index=False)

    with_images = int(frame["image_url"].fillna("").astype(str).str.strip().ne("").sum())
    print(f"Rows: {len(frame)}")
    print(f"Rows with image: {with_images}")
    print(f"Saved: {output_path}")
