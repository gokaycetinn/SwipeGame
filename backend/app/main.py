import csv
from pathlib import Path
from typing import Any

from fastapi import Depends, FastAPI
from sqlmodel import Session, select

from app.database import create_db_and_tables, get_session
from app.models import (
    Player,
    PlayerCreate,
    RuleTemplate,
    RuleTemplateCreate,
    Stadium,
    StadiumCreate,
)
from app.schemas import GenerateQuestionsRequest, QuestionCard
from app.services.question_engine import generate_questions

app = FastAPI(title="FutSwipe API", version="0.1.0")

DATA_DIR = Path(__file__).resolve().parents[1] / "data"


@app.on_event("startup")
def on_startup() -> None:
    create_db_and_tables()


@app.get("/health")
def health_check():
    return {"status": "ok"}


def _seed_default_rules_internal(session: Session) -> int:
    defaults = [
        RuleTemplateCreate(
            key="played_man_city",
            label_tr="Manchester City formasini giydi",
            target_type="player",
            difficulty=1,
        ),
        RuleTemplateCreate(
            key="is_forward",
            label_tr="Forvet pozisyonunda oynadi",
            target_type="player",
            difficulty=1,
        ),
        RuleTemplateCreate(
            key="age_under_23",
            label_tr="23 yasindan kucuk",
            target_type="player",
            difficulty=2,
        ),
        RuleTemplateCreate(
            key="nationality_brazil",
            label_tr="Milliyeti Brezilya",
            target_type="player",
            difficulty=2,
        ),
        RuleTemplateCreate(
            key="capacity_over_50000",
            label_tr="Stadyum kapasitesi 50.000 ustu",
            target_type="stadium",
            difficulty=1,
        ),
        RuleTemplateCreate(
            key="located_in_england",
            label_tr="Stadyum Ingiltere'de",
            target_type="stadium",
            difficulty=1,
        ),
    ]

    existing_keys = {rule.key for rule in session.exec(select(RuleTemplate)).all()}
    inserted = 0
    for item in defaults:
        if item.key in existing_keys:
            continue
        entity = RuleTemplate.model_validate(item)
        session.add(entity)
        inserted += 1

    session.commit()
    return inserted


@app.post("/players", response_model=Player)
def create_player(payload: PlayerCreate, session: Session = Depends(get_session)):
    player = Player.model_validate(payload)
    session.add(player)
    session.commit()
    session.refresh(player)
    return player


@app.get("/players", response_model=list[Player])
def list_players(session: Session = Depends(get_session)):
    return session.exec(select(Player)).all()


@app.post("/stadiums", response_model=Stadium)
def create_stadium(payload: StadiumCreate, session: Session = Depends(get_session)):
    stadium = Stadium.model_validate(payload)
    session.add(stadium)
    session.commit()
    session.refresh(stadium)
    return stadium


@app.get("/stadiums", response_model=list[Stadium])
def list_stadiums(session: Session = Depends(get_session)):
    return session.exec(select(Stadium)).all()


@app.post("/rules", response_model=RuleTemplate)
def create_rule(payload: RuleTemplateCreate, session: Session = Depends(get_session)):
    rule = RuleTemplate.model_validate(payload)
    session.add(rule)
    session.commit()
    session.refresh(rule)
    return rule


@app.get("/rules", response_model=list[RuleTemplate])
def list_rules(session: Session = Depends(get_session)):
    return session.exec(select(RuleTemplate)).all()


@app.post("/rules/seed")
def seed_default_rules(session: Session = Depends(get_session)):
    inserted = _seed_default_rules_internal(session)
    return {"inserted": inserted}


@app.post("/questions/generate", response_model=list[QuestionCard])
def generate_questions_endpoint(
    payload: GenerateQuestionsRequest,
    session: Session = Depends(get_session),
):
    return generate_questions(session, payload)


def _flush_player_batch(
    session: Session,
    pending_rows: list[dict[str, Any]],
    errors: list[str],
) -> dict[str, int]:
    if not pending_rows:
        return {
            "imported": 0,
            "committed_batches": 0,
            "retry_batches": 0,
            "retry_row_success": 0,
            "retry_row_failed": 0,
        }

    try:
        for row in pending_rows:
            payload = PlayerCreate(**row["payload"])
            entity = Player.model_validate(payload)
            session.add(entity)
        session.commit()
        return {
            "imported": len(pending_rows),
            "committed_batches": 1,
            "retry_batches": 0,
            "retry_row_success": 0,
            "retry_row_failed": 0,
        }
    except Exception as exc:
        session.rollback()
        errors.append(f"batch commit hatasi: {str(exc)[:140]}")

    retry_row_success = 0
    retry_row_failed = 0
    for row in pending_rows:
        try:
            payload = PlayerCreate(**row["payload"])
            entity = Player.model_validate(payload)
            session.add(entity)
            session.commit()
            retry_row_success += 1
        except Exception as row_exc:
            session.rollback()
            retry_row_failed += 1
            errors.append(
                f"players_enriched.csv satir {row['line']}: retry basarisiz ({str(row_exc)[:120]})"
            )

    return {
        "imported": retry_row_success,
        "committed_batches": 1,
        "retry_batches": 1,
        "retry_row_success": retry_row_success,
        "retry_row_failed": retry_row_failed,
    }


def _load_players_csv(session: Session, path: Path, batch_size: int = 1000) -> dict:
    imported = 0
    skipped = 0
    errors: list[str] = []
    total_rows = 0
    valid_rows = 0
    committed_batches = 0
    retry_batches = 0
    retry_row_success = 0
    retry_row_failed = 0
    safe_batch_size = max(100, min(batch_size, 10000))
    pending_rows: list[dict[str, Any]] = []

    existing = {
        (p.full_name.lower(), p.nationality.lower(), p.club.lower())
        for p in session.exec(select(Player)).all()
    }
    seen_in_file: set[tuple[str, str, str]] = set()

    with path.open("r", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for index, row in enumerate(reader, start=2):
            total_rows += 1
            full_name = (row.get("name") or "").strip()
            nationality = (row.get("nationality") or "").strip()
            club = (row.get("club") or "").strip()
            position = (row.get("position") or "").strip()
            age_raw = (row.get("age") or "").strip()
            photo_url = (row.get("image_url") or "").strip()

            if not all([full_name, nationality, club, position, age_raw]):
                skipped += 1
                errors.append(f"players_enriched.csv satir {index}: zorunlu alan eksik")
                continue

            try:
                age = int(age_raw)
            except ValueError:
                skipped += 1
                errors.append(f"players_enriched.csv satir {index}: age sayi degil")
                continue

            unique_key = (full_name.lower(), nationality.lower(), club.lower())
            if unique_key in existing or unique_key in seen_in_file:
                skipped += 1
                continue

            pending_rows.append(
                {
                    "line": index,
                    "unique_key": unique_key,
                    "payload": {
                        "full_name": full_name,
                        "nationality": nationality,
                        "club": club,
                        "position": position,
                        "age": age,
                        "photo_url": photo_url,
                    },
                }
            )
            seen_in_file.add(unique_key)
            valid_rows += 1

            if len(pending_rows) >= safe_batch_size:
                result = _flush_player_batch(session, pending_rows, errors)
                imported += result["imported"]
                committed_batches += result["committed_batches"]
                retry_batches += result["retry_batches"]
                retry_row_success += result["retry_row_success"]
                retry_row_failed += result["retry_row_failed"]
                for row in pending_rows:
                    existing.add(row["unique_key"])
                print(
                    f"players import progress: processed={total_rows} imported={imported} skipped={skipped} batches={committed_batches}"
                )
                pending_rows = []

    if pending_rows:
        result = _flush_player_batch(session, pending_rows, errors)
        imported += result["imported"]
        committed_batches += result["committed_batches"]
        retry_batches += result["retry_batches"]
        retry_row_success += result["retry_row_success"]
        retry_row_failed += result["retry_row_failed"]
        for row in pending_rows:
            existing.add(row["unique_key"])
        print(
            f"players import progress: processed={total_rows} imported={imported} skipped={skipped} batches={committed_batches}"
        )

    return {
        "imported": imported,
        "skipped": skipped,
        "total_rows": total_rows,
        "valid_rows": valid_rows,
        "batch_size": safe_batch_size,
        "committed_batches": committed_batches,
        "retry_report": {
            "retry_batches": retry_batches,
            "retry_row_success": retry_row_success,
            "retry_row_failed": retry_row_failed,
        },
        "errors": errors[:20],
    }


@app.post("/import/players/csv")
def import_players_csv(
    clear_existing: bool = False,
    batch_size: int = 1000,
    session: Session = Depends(get_session),
):
    players_path = DATA_DIR / "players_enriched.csv"

    if not players_path.exists():
        return {
            "ok": False,
            "message": "players_enriched.csv bulunamadi",
            "expected_path": str(players_path),
        }

    if clear_existing:
        entities = session.exec(select(Player)).all()
        for entity in entities:
            session.delete(entity)
        session.commit()

    player_result = _load_players_csv(session, players_path, batch_size=batch_size)

    return {
        "ok": True,
        "source": str(players_path),
        "players": player_result,
    }


@app.post("/mvp/bootstrap")
def bootstrap_mvp(
    clear_existing: bool = True,
    batch_size: int = 1000,
    session: Session = Depends(get_session),
):
    players_path = DATA_DIR / "players_enriched.csv"
    if not players_path.exists():
        return {
            "ok": False,
            "message": "players_enriched.csv bulunamadi",
            "expected_path": str(players_path),
        }

    if clear_existing:
        for model in [Player, RuleTemplate, Stadium]:
            entities = session.exec(select(model)).all()
            for entity in entities:
                session.delete(entity)
        session.commit()

    player_result = _load_players_csv(session, players_path, batch_size=batch_size)
    rules_inserted = _seed_default_rules_internal(session)

    player_count = len(session.exec(select(Player)).all())
    rule_count = len(session.exec(select(RuleTemplate)).all())
    stadium_count = len(session.exec(select(Stadium)).all())

    return {
        "ok": True,
        "source": str(players_path),
        "players": player_result,
        "rules_inserted": rules_inserted,
        "totals": {
            "players": player_count,
            "rules": rule_count,
            "stadiums": stadium_count,
        },
    }
