import argparse
import subprocess
import sys
from pathlib import Path


def run(command: list[str]) -> None:
    print("Running:", " ".join(command))
    subprocess.run(command, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run end-to-end dataset pipeline")
    parser.add_argument("--raw", required=True, help="Raw FIFA CSV path")
    parser.add_argument(
        "--clean-out",
        default="backend/data/players_clean.csv",
        help="Cleaned output CSV",
    )
    parser.add_argument(
        "--enriched-out",
        default="backend/data/players_enriched.csv",
        help="Image enriched output CSV",
    )
    parser.add_argument(
        "--image-limit",
        type=int,
        default=0,
        help="Image enrichment limit (0 = all)",
    )

    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]

    run(
        [
            sys.executable,
            str(root / "backend/scripts/clean_players_csv.py"),
            "--in",
            args.raw,
            "--out",
            args.clean_out,
        ]
    )

    run(
        [
            sys.executable,
            str(root / "backend/scripts/enrich_player_images.py"),
            "--in",
            args.clean_out,
            "--out",
            args.enriched_out,
            "--limit",
            str(args.image_limit),
        ]
    )

    print("Pipeline completed.")
    print(f"Enriched CSV: {args.enriched_out}")
    print("Now call POST /import/players/csv?clear_existing=true")
