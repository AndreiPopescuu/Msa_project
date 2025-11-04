from sqlalchemy.orm import Session
from models.user import User
from models.drink import Drink
from models.session import Session as UserSession
from schemas import UserCreate, DrinkCreate
from datetime import datetime

def create_user(db: Session, user: UserCreate):
    new_user = User(
        name=user.name,
        email=user.email,
        password=user.password,
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
    """
    Calculează nivelul de sobrietate al unui utilizator în funcție de băuturile consumate
    și timpul scurs de la ultima băutură.
    Returnează un scor între 0.0 (beat) și 1.0 (treaz).
    """
    user = db.query(User).filter(User.id == user_id).first()
    drinks = db.query(Drink).filter(Drink.user_id == user_id).all()

    # Dacă nu există utilizator sau băuturi, considerăm utilizatorul treaz
    if not user or not drinks:
        return 1.0

    # Calculează alcoolul total (în grame)
    total_alcohol_g = sum([
        d.volume_ml * (d.alcohol_percent / 100) * 0.789 for d in drinks
    ])

    # Conversie în uncii (oz)
    alcohol_oz = total_alcohol_g / 28.3495

    # Greutatea în livre (lb)
    weight_lb = (user.weight or 70) * 2.20462  # default 70 kg dacă e null

    # Coeficient distribuție alcool (bărbat/femeie)
    r = 0.73 if (user.gender and user.gender.lower() == "male") else 0.66

    # Timpul scurs de la ultima băutură (în ore)
    last_drink_time = max([d.created_at for d in drinks])
    hours_since = (datetime.utcnow() - last_drink_time).total_seconds() / 3600

    # Formula BAC corectă
    bac = (alcohol_oz * 5.14 / (weight_lb * r)) - (0.015 * hours_since)

    # Dacă BAC < 0, îl considerăm 0
    bac = max(0.0, bac)

    # Calculăm nivelul de sobrietate (0 - beat, 1 - treaz)
    sober_score = max(0.0, 1 - min(1.0, bac / 0.25))

    # Debug în consolă (opțional)
    print("DEBUG →",
          f"Alcool total: {total_alcohol_g:.2f}g | Alcool (oz): {alcohol_oz:.2f} | Greutate: {weight_lb:.2f}lb | r: {r} | Ore: {hours_since:.2f} | BAC: {bac:.3f} | Scor: {sober_score:.2f}")

    return round(sober_score, 2)


def get_milestone(db: Session, user_id: int):
    """Returnează starea utilizatorului în funcție de sobriety_level."""
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
