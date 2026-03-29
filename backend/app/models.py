from typing import Optional

from sqlmodel import Field, SQLModel


class PlayerBase(SQLModel):
    first_name: str
    last_name: str
    photo_url: str
    country: str
    primary_position: str
    clubs_csv: str = ""
    competitions_won_csv: str = ""
    leagues_played_csv: str = ""


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
