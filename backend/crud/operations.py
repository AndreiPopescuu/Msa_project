from sqlalchemy.orm import Session
from datetime import datetime
from fastapi import HTTPException

from models.user import User
from models.drink import Drink
from schemas import UserCreate, DrinkCreate


# FĂRĂ importuri de securitate/hashing

def create_user(db: Session, user: UserCreate):
    # 1. Verificăm totuși dacă emailul există (ca să nu avem erori de DB)
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Există deja un cont cu acest email.")

    # 2. Creăm utilizatorul cu parola TEXT SIMPLU
    new_user = User(
        name=user.name,
        email=user.email,
        password=user.password,  # <--- Se salvează direct
        gender=user.gender,
        height=user.height,
        weight=user.weight
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


def add_drink(db: Session, drink: DrinkCreate):
    new_drink = Drink(
        user_id=drink.user_id,
        name=drink.name,
        alcohol_percent=drink.alcohol_percent,
        volume_ml=drink.volume_ml
    )
    db.add(new_drink)
    db.commit()
    db.refresh(new_drink)
    return new_drink


def get_sobriety_level(db: Session, user_id: int):
    # ... (Codul tău rămâne identic aici)
    user = db.query(User).filter(User.id == user_id).first()
    drinks = db.query(Drink).filter(Drink.user_id == user_id).all()

    if not user or not drinks:
        return 1.0

    total_alcohol_g = sum([
        d.volume_ml * (d.alcohol_percent / 100) * 0.789 for d in drinks
    ])

    alcohol_oz = total_alcohol_g / 28.3495
    weight_lb = (user.weight or 70) * 2.20462
    r = 0.73 if (user.gender and user.gender.lower() == "male") else 0.66

    last_drink_time = max([d.created_at for d in drinks])
    hours_since = (datetime.utcnow() - last_drink_time).total_seconds() / 3600

    bac = (alcohol_oz * 5.14 / (weight_lb * r)) - (0.015 * hours_since)
    bac = max(0.0, bac)
    sober_score = max(0.0, 1 - min(1.0, bac / 0.25))

    return round(sober_score, 2)


def get_milestone(db: Session, user_id: int):
    # ... (Codul tău rămâne identic aici)
    level = get_sobriety_level(db, user_id)

    if level >= 0.9:
        status = "Sober 🟢"
        message = "You're completely sober. Great job!"
    elif level >= 0.75:
        status = "Mild Drunk 🟡"
        message = "You're feeling it a bit — stay aware!"
    elif level >= 0.5:
        status = "Drunk 🟠"
        message = "You're drunk — take it easy!"
    elif level >= 0.25:
        status = "Very Drunk 🔴"
        message = "You're very drunk — drink water and rest!"
    else:
        status = "Wasted ⚫"
        message = "You're completely wasted. Please don’t drive!"

    return {
        "user_id": user_id,
        "sobriety_level": level,
        "status": status,
        "message": message
    }