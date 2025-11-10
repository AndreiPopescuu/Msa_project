from fastapi import FastAPI, Depends, File, UploadFile
from sqlalchemy.orm import Session
from database import Base, engine, SessionLocal
from crud import operations
from schemas import UserCreate, DrinkCreate
from dotenv import load_dotenv
from openai import OpenAI
import base64, os, json

# -----------------------------
#  Inițializare
# -----------------------------
load_dotenv()  
Base.metadata.create_all(bind=engine)
app = FastAPI()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -----------------------------
#  Endpointuri existente
# -----------------------------
@app.get("/")
def home():
    return {"message": "Backend FastAPI + MySQL running 🚀"}

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

from transformers import pipeline
from PIL import Image
import io



image_classifier = pipeline("image-classification", model="google/vit-base-patch16-224")
#image_classifier = pipeline("image-classification", model="dima806/food101-vit-base-patch16-224")


@app.post("/identifyDrink")
async def identify_drink_local(file: UploadFile = File(...), user_id: int = 1, db: Session = Depends(get_db)):
    """
    Primește o imagine, folosește un model open-source (ViT) pentru clasificare,
    și adaugă automat băutura în baza de date.
    """
    # citește imaginea primită
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes))

    # clasifică imaginea
    predictions = image_classifier(image)
    top = predictions[0]

    name = top["label"]
    confidence = round(top["score"] * 100, 2)

    # simplificăm: punem valori default pentru alcool și volum
    new_drink = DrinkCreate(
        user_id=user_id,
        name=name,
        alcohol_percent=5.0,  # poți schimba în funcție de categorie
        volume_ml=500
    )

    operations.add_drink(db, new_drink)

    return {
        "message": "Drink added successfully 🍺",
        "prediction": {"label": name, "confidence": confidence},
        "data": new_drink
    }
