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
            key="won_ucl",
            label_tr="Sampiyonlar Ligi kazandi",
            target_type="player",
            difficulty=2,
        ),
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
            key="played_serie_a",
            label_tr="Serie A'da oynadi",
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
        (p.first_name.lower(), p.last_name.lower(), p.country.lower())
        for p in session.exec(select(Player)).all()
    }

    with path.open("r", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for index, row in enumerate(reader, start=2):
            first_name = (row.get("first_name") or "").strip()
            last_name = (row.get("last_name") or "").strip()
            photo_url = (row.get("photo_url") or "").strip()
            country = (row.get("country") or "").strip()
            primary_position = (row.get("primary_position") or "").strip()

            if not all([first_name, last_name, photo_url, country, primary_position]):
                skipped += 1
                errors.append(f"players.csv satir {index}: zorunlu alan eksik")
                continue

            unique_key = (first_name.lower(), last_name.lower(), country.lower())
            if unique_key in existing:
                skipped += 1
                continue

            payload = PlayerCreate(
                first_name=first_name,
                last_name=last_name,
                photo_url=photo_url,
                country=country,
                primary_position=primary_position,
                clubs_csv=(row.get("clubs_csv") or "").strip(),
                competitions_won_csv=(row.get("competitions_won_csv") or "").strip(),
                leagues_played_csv=(row.get("leagues_played_csv") or "").strip(),
            )
            entity = Player.model_validate(payload)
            session.add(entity)
            imported += 1
            existing.add(unique_key)

    return {"imported": imported, "skipped": skipped, "errors": errors[:20]}


def _load_stadiums_csv(session: Session, path: Path) -> dict:
    imported = 0
    skipped = 0
    errors: list[str] = []

    existing = {(s.name.lower(), s.city.lower()) for s in session.exec(select(Stadium)).all()}

    with path.open("r", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for index, row in enumerate(reader, start=2):
            name = (row.get("name") or "").strip()
            city = (row.get("city") or "").strip()
            country = (row.get("country") or "").strip()
            photo_url = (row.get("photo_url") or "").strip()
            capacity_raw = (row.get("capacity") or "").strip()

            if not all([name, city, country, photo_url, capacity_raw]):
                skipped += 1
                errors.append(f"stadiums.csv satir {index}: zorunlu alan eksik")
                continue

            try:
                capacity = int(capacity_raw)
            except ValueError:
                skipped += 1
                errors.append(f"stadiums.csv satir {index}: capacity sayi degil")
                continue

            unique_key = (name.lower(), city.lower())
            if unique_key in existing:
                skipped += 1
                continue

            payload = StadiumCreate(
                name=name,
                city=city,
                country=country,
                capacity=capacity,
                photo_url=photo_url,
                clubs_csv=(row.get("clubs_csv") or "").strip(),
            )
            entity = Stadium.model_validate(payload)
            session.add(entity)
            imported += 1
            existing.add(unique_key)

    return {"imported": imported, "skipped": skipped, "errors": errors[:20]}


def _load_rules_csv(session: Session, path: Path) -> dict:
    imported = 0
    skipped = 0
    errors: list[str] = []

    existing = {r.key for r in session.exec(select(RuleTemplate)).all()}

    with path.open("r", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for index, row in enumerate(reader, start=2):
            key = (row.get("key") or "").strip()
            label_tr = (row.get("label_tr") or "").strip()
            target_type = (row.get("target_type") or "").strip().lower()
            difficulty_raw = (row.get("difficulty") or "").strip()

            if not all([key, label_tr, target_type, difficulty_raw]):
                skipped += 1
                errors.append(f"rules.csv satir {index}: zorunlu alan eksik")
                continue

            if target_type not in {"player", "stadium"}:
                skipped += 1
                errors.append(f"rules.csv satir {index}: target_type gecersiz")
                continue

            try:
                difficulty = int(difficulty_raw)
            except ValueError:
                skipped += 1
                errors.append(f"rules.csv satir {index}: difficulty sayi degil")
                continue

            if key in existing:
                skipped += 1
                continue

            payload = RuleTemplateCreate(
                key=key,
                label_tr=label_tr,
                target_type=target_type,
                difficulty=difficulty,
            )
            entity = RuleTemplate.model_validate(payload)
            session.add(entity)
            imported += 1
            existing.add(key)

    return {"imported": imported, "skipped": skipped, "errors": errors[:20]}


@app.post("/import/csv")
def import_csv_data(clear_existing: bool = False, session: Session = Depends(get_session)):
    players_path = DATA_DIR / "players.csv"
    stadiums_path = DATA_DIR / "stadiums.csv"
    rules_path = DATA_DIR / "rules.csv"

    missing_files = [
        str(path.name)
        for path in [players_path, stadiums_path, rules_path]
        if not path.exists()
    ]
    if missing_files:
        return {
            "ok": False,
            "message": "Eksik CSV dosyalari var",
            "missing_files": missing_files,
        }

    if clear_existing:
        for model in [RuleTemplate, Player, Stadium]:
            entities = session.exec(select(model)).all()
            for entity in entities:
                session.delete(entity)
        session.commit()

    player_result = _load_players_csv(session, players_path)
    stadium_result = _load_stadiums_csv(session, stadiums_path)
    rule_result = _load_rules_csv(session, rules_path)
    session.commit()

    return {
        "ok": True,
        "source": str(DATA_DIR),
        "players": player_result,
        "stadiums": stadium_result,
        "rules": rule_result,
    }
