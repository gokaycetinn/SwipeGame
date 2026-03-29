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
