import random
from typing import Iterable

from sqlmodel import Session, select

from app.models import Player, RuleTemplate, Stadium
from app.schemas import GenerateQuestionsRequest, QuestionCard


def _contains(csv_value: str, token: str) -> bool:
    values = [v.strip().lower() for v in csv_value.split(",") if v.strip()]
    return token.lower() in values


def _evaluate_player_rule(player: Player, key: str) -> bool:
    if key == "played_man_city":
        club = player.club.strip().lower()
        return "manchester city" in club or "man city" in club
    if key == "is_forward":
        position = player.position.strip().lower()
        return (
            "forward" in position
            or "striker" in position
            or position in {"st", "cf", "rw", "lw"}
        )
    if key == "age_under_23":
        return player.age < 23
    if key == "nationality_brazil":
        return player.nationality.strip().lower() == "brazil"
    return False


def _evaluate_stadium_rule(stadium: Stadium, key: str) -> bool:
    if key == "capacity_over_50000":
        return stadium.capacity >= 50000
    if key == "located_in_england":
        return stadium.country.strip().lower() == "england"
    return False


def _pick_random(items: Iterable, count: int):
    data = list(items)
    if not data:
        return []
    if len(data) >= count:
        return random.sample(data, count)
    return [random.choice(data) for _ in range(count)]


def generate_questions(session: Session, payload: GenerateQuestionsRequest) -> list[QuestionCard]:
    rules = session.exec(select(RuleTemplate)).all()
    players = session.exec(select(Player)).all()
    stadiums = session.exec(select(Stadium)).all()

    if not rules:
        return []

    questions: list[QuestionCard] = []
    safe_count = max(1, min(payload.count, 50))

    for _ in range(safe_count):
        if payload.target_type == "player":
            target_type = "player"
        elif payload.target_type == "stadium":
            target_type = "stadium"
        else:
            target_type = random.choice(["player", "stadium"])

        scoped_rules = [r for r in rules if r.target_type == target_type]
        if not scoped_rules:
            continue

        rule = random.choice(scoped_rules)

        if target_type == "player" and players:
            player = random.choice(players)
            expected = _evaluate_player_rule(player, rule.key)
            questions.append(
                QuestionCard(
                    entity_type="player",
                    entity_id=player.id or 0,
                    title=player.full_name,
                    subtitle=f"{player.position.upper()} • {player.nationality.upper()} • {player.club}",
                    image_url=player.photo_url,
                    rule_text=rule.label_tr,
                    expected_answer=expected,
                    difficulty=rule.difficulty,
                )
            )
        elif target_type == "stadium" and stadiums:
            stadium = random.choice(stadiums)
            expected = _evaluate_stadium_rule(stadium, rule.key)
            questions.append(
                QuestionCard(
                    entity_type="stadium",
                    entity_id=stadium.id or 0,
                    title=stadium.name,
                    subtitle=f"{stadium.city} • {stadium.country}",
                    image_url=stadium.photo_url,
                    rule_text=rule.label_tr,
                    expected_answer=expected,
                    difficulty=rule.difficulty,
                )
            )

    return questions
