from typing import Optional

from sqlmodel import Field, SQLModel


class PlayerBase(SQLModel):
    full_name: str
    nationality: str
    club: str
    position: str
    age: int
    photo_url: str = ""


class Player(PlayerBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)


class PlayerCreate(PlayerBase):
    pass


class StadiumBase(SQLModel):
    name: str
    city: str
    country: str
    capacity: int
    photo_url: str
    clubs_csv: str = ""


class Stadium(StadiumBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)


class StadiumCreate(StadiumBase):
    pass


class RuleTemplateBase(SQLModel):
    key: str
    label_tr: str
    target_type: str
    difficulty: int = 1


class RuleTemplate(RuleTemplateBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)


class RuleTemplateCreate(RuleTemplateBase):
    pass
