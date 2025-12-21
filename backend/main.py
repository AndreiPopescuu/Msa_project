from fastapi import FastAPI, Depends, File, UploadFile, HTTPException
from sqlalchemy.orm import Session
from database import Base, engine, SessionLocal
from crud import operations
from schemas import UserCreate, DrinkCreate
from dotenv import load_dotenv
from openai import OpenAI
from pydantic import BaseModel
import base64, os, json
from fastapi.middleware.cors import CORSMiddleware # <--- 1. IMPORTĂ ASTA

# ⚠️ IMPORTANT: Trebuie să importăm modelul User pentru a face interogări directe în login
# Asigură-te că folderul tău 'models' are un fișier 'user.py' și clasa se numește 'User'
import models.user

# -----------------------------
#  Inițializare
# -----------------------------
load_dotenv()
Base.metadata.create_all(bind=engine)
app = FastAPI()


origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "*", # Permite accesul de oriunde (ideal pt dev)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"], # Permite orice metodă (GET, POST, etc)
    allow_headers=["*"],
)

# client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# -----------------------------
#  Scheme Noi (Pentru Login)
# -----------------------------
class LoginRequest(BaseModel):
    email: str
    password: str


# -----------------------------
#  Endpointuri
# -----------------------------
@app.get("/")
def home():
    return {"message": "Backend FastAPI + MySQL running 🚀"}


# --- Endpoint NOU pentru LOGIN ---
@app.post("/login")
@app.post("/login")
def login(creds: LoginRequest, db: Session = Depends(get_db)):
    # 1. Căutăm userul
    user = db.query(models.user.User).filter(models.user.User.email == creds.email).first()

    if not user:
        raise HTTPException(status_code=404, detail="Utilizatorul nu există")

    # 2. Verificăm parola TEXT VS TEXT
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


# -----------------------------
#  AI Component
# -----------------------------
from transformers import pipeline
from PIL import Image
import io

image_classifier = pipeline("image-classification", model="google/vit-base-patch16-224")


# image_classifier = pipeline("image-classification", model="dima806/food101-vit-base-patch16-224")

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