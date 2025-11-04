from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    gender: Optional[str] = None
    height: Optional[int] = None
    weight: Optional[int] = None


class DrinkCreate(BaseModel):
    user_id: int
    name: str
    alcohol_percent: float
    volume_ml: float
