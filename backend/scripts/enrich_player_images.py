import argparse
import os
import time
from pathlib import Path
from typing import Optional
from urllib.parse import quote

import pandas as pd
import requests

WIKIPEDIA_SUMMARY_API = "https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
WIKIPEDIA_SEARCH_API = "https://en.wikipedia.org/w/api.php"
WIKIMEDIA_SEARCH_API = "https://commons.wikimedia.org/w/api.php"
BING_IMAGE_SEARCH_API = "https://api.bing.microsoft.com/v7.0/images/search"


def find_wikipedia_title(query: str) -> Optional[str]:
    params = {
        "action": "query",
        "format": "json",
        "list": "search",
        "srsearch": query,
        "srlimit": 1,
    }

    try:
        response = requests.get(WIKIPEDIA_SEARCH_API, params=params, timeout=20)
        if response.status_code != 200:
            return None
        payload = response.json()
        search_rows = payload.get("query", {}).get("search", [])
        if not search_rows:
            return None
        return str(search_rows[0].get("title", "")).strip() or None
    except Exception:
        return None


def get_wikipedia_thumbnail(name: str) -> Optional[str]:
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


def get_wikipedia_thumbnail_by_search(query: str) -> Optional[str]:
    title = find_wikipedia_title(query)
    if not title:
        return None
    return get_wikipedia_thumbnail(title)


def get_wikimedia_image(query: str) -> Optional[str]:
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
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


def get_bing_image(query: str) -> Optional[str]:
    api_key = os.getenv("BING_IMAGE_API_KEY", "").strip()
    if not api_key:
        return None

    headers = {"Ocp-Apim-Subscription-Key": api_key}
    params = {
        "q": query,
        "count": 1,
        "safeSearch": "Strict",
        "imageType": "Photo",
    }

    try:
        response = requests.get(BING_IMAGE_SEARCH_API, headers=headers, params=params, timeout=20)
        if response.status_code != 200:
            return None
        payload = response.json()
        values = payload.get("value", [])
        if not values:
            return None
        return str(values[0].get("contentUrl", "")).strip() or None
    except Exception:
        return None


def get_player_image(name: str, providers: list[str]) -> Optional[str]:
    query = f"{name} football"

    for provider in providers:
        provider_key = provider.strip().lower()
        if provider_key == "wikipedia":
            image = get_wikipedia_thumbnail(name)
            if image:
                return image
            image = get_wikipedia_thumbnail_by_search(query)
            if image:
                return image
        elif provider_key == "wikimedia":
            image = get_wikimedia_image(query)
            if image:
                return image
        elif provider_key == "bing":
            image = get_bing_image(query)
            if image:
                return image

    return None


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
    parser.add_argument(
        "--providers",
        default="wikipedia,wikimedia,bing",
        help="Comma-separated providers in order",
    )

    args = parser.parse_args()

    input_path = Path(args.input_path)
    output_path = Path(args.out)

    frame = pd.read_csv(input_path)
    if "image_url" not in frame.columns:
        frame["image_url"] = ""

    providers = [p.strip().lower() for p in args.providers.split(",") if p.strip()]
    if not providers:
        providers = ["wikipedia", "wikimedia", "bing"]

    total = len(frame) if args.limit <= 0 else min(args.limit, len(frame))

    for idx in range(total):
        row = frame.iloc[idx]
        if str(row.get("image_url", "")).strip():
            continue

        name = str(row["name"]).strip()
        if not name:
            continue

        image_url = get_player_image(name, providers)
        if image_url:
            frame.at[idx, "image_url"] = image_url

        time.sleep(max(args.sleep, 0.0))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    frame.to_csv(output_path, index=False)

    with_images = int(frame["image_url"].fillna("").astype(str).str.strip().ne("").sum())
    print(f"Rows: {len(frame)}")
    print(f"Rows with image: {with_images}")
    print(f"Saved: {output_path}")
