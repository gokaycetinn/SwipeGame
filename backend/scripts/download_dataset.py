import argparse
from pathlib import Path

import requests


def download_file(url: str, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with requests.get(url, stream=True, timeout=60) as response:
        response.raise_for_status()
        with output_path.open("wb") as file:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    file.write(chunk)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download a raw FIFA CSV dataset")
    parser.add_argument("--url", required=True, help="Direct CSV file URL")
    parser.add_argument(
        "--out",
        default="backend/data/raw/fifa_players.csv",
        help="Destination CSV path",
    )

    args = parser.parse_args()
    output = Path(args.out)

    print(f"Downloading dataset from: {args.url}")
    download_file(args.url, output)
    print(f"Saved: {output}")
