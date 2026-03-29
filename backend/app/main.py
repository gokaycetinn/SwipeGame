import csv
from pathlib import Path

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
    return {"inserted": inserted}


@app.post("/questions/generate", response_model=list[QuestionCard])
def generate_questions_endpoint(
    payload: GenerateQuestionsRequest,
    session: Session = Depends(get_session),
):
    return generate_questions(session, payload)


def _load_players_csv(session: Session, path: Path) -> dict:
    imported = 0
    skipped = 0
    errors: list[str] = []

    existing = {
        (p.full_name.lower(), p.nationality.lower(), p.club.lower())
        for p in session.exec(select(Player)).all()
    }

    with path.open("r", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for index, row in enumerate(reader, start=2):
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
            if unique_key in existing:
                skipped += 1
                continue

            payload = PlayerCreate(
                full_name=full_name,
                nationality=nationality,
                club=club,
                position=position,
                age=age,
                photo_url=photo_url,
            )
            entity = Player.model_validate(payload)
            session.add(entity)
            imported += 1
            existing.add(unique_key)

    return {"imported": imported, "skipped": skipped, "errors": errors[:20]}


@app.post("/import/players/csv")
def import_players_csv(clear_existing: bool = False, session: Session = Depends(get_session)):
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

    player_result = _load_players_csv(session, players_path)
    session.commit()

    return {
        "ok": True,
        "source": str(players_path),
        "players": player_result,
    }
