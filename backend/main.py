from fastapi import FastAPI, Depends, File, UploadFile, HTTPException
from sqlalchemy.orm import Session
from database import Base, engine, SessionLocal
from crud import operations
from schemas import UserCreate, DrinkCreate
from dotenv import load_dotenv
from pydantic import BaseModel
import io

from fastapi.middleware.cors import CORSMiddleware
from transformers import pipeline
from PIL import Image

from models.user import User
from models.drink import Drink

load_dotenv()
Base.metadata.create_all(bind=engine)
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


image_classifier = None


class LoginRequest(BaseModel):
    email: str
    password: str


class UserUpdate(BaseModel):
    name: str
    weight: float
    height: float


@app.get("/")
def home():
    return {"message": "Backend FastAPI + PostgreSQL running 🚀"}


@app.post("/login")
def login(creds: LoginRequest, db: Session = Depends(get_db)):
    # Căutăm userul
    user = db.query(User).filter(User.email == creds.email).first()

    if not user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu există")

    if user.password != creds.password:
        raise HTTPException(status_code=401, detail="Parolă incorectă")

    return {
        "message": "Login successful",
        "user_id": user.id,
        "username": user.name,
        "email": user.email
    }


@app.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    return operations.create_user(db, user)


@app.post("/add_drink")
def add_drink(drink: DrinkCreate, db: Session = Depends(get_db)):
    return operations.add_drink(db, drink)


@app.get("/sobriety/{user_id}")
def get_sobriety(user_id: int, db: Session = Depends(get_db)):
    level = operations.get_sobriety_level(db, user_id)
    return {"user_id": user_id, "sobriety_level": level}


@app.get("/milestones/{user_id}")
def get_milestone_status(user_id: int, db: Session = Depends(get_db)):
    return operations.get_milestone(db, user_id)


@app.get("/drinks/{user_id}")
def get_user_drinks(user_id: int, db: Session = Depends(get_db)):
    return db.query(Drink) \
        .filter(Drink.user_id == user_id) \
        .order_by(Drink.id.desc()) \
        .all()


@app.put("/users/{user_id}")
def update_user(user_id: int, user_update: UserUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db_user.name = user_update.name
    db_user.weight = user_update.weight
    db_user.height = user_update.height

    db.commit()
    db.refresh(db_user)
    return {"message": "Profil actualizat!", "user": db_user}


import gc

@app.post("/identify_drink")
async def identify_drink(file: UploadFile = File(...)):
    global image_classifier
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        image = image.resize((128, 128))

        if image_classifier is None:
            print("⏳ Loading Small AI Model (MobileNetV2)...")
            image_classifier = pipeline("image-classification", model="google/mobilenet_v2_1.0_224")


        predictions = image_classifier(image)


        del image
        del image_bytes
        gc.collect()

        top = predictions[0]
        name = top["label"]
        name_lower = name.lower()

        estimated_abv = 5.0
        if any(x in name_lower for x in ["vodka", "whisky", "cognac", "gin", "rum", "tequila", "spirit", "whiskey"]):
            estimated_abv = 40.0
        elif any(x in name_lower for x in ["wine", "champagne", "prosecco", "claret"]):
            estimated_abv = 12.0
        elif "beer" in name_lower or "pilsner" in name_lower:
            estimated_abv = 5.0

        return {
            "name": name.capitalize(),
            "abv": estimated_abv,
            "confidence": round(top["score"] * 100, 2)
        }

    except Exception as e:
        print(f"❌ CRASH RAM: {e}")
        return {"name": "Eroare Procesare", "abv": 0.0, "confidence": 0}



