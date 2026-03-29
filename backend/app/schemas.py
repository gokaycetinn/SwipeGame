from typing import Literal

from pydantic import BaseModel


class QuestionCard(BaseModel):
    entity_type: Literal["player", "stadium"]
    entity_id: int
    title: str
    subtitle: str
    image_url: str
    rule_text: str
    expected_answer: bool
    difficulty: int


class GenerateQuestionsRequest(BaseModel):
    count: int = 10
    target_type: Literal["player", "stadium", "mixed"] = "mixed"
