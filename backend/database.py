from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

load_dotenv()

# 1. Încercăm să luăm URL-ul de la Render (PostgreSQL)
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# 2. Logica de selecție
if SQLALCHEMY_DATABASE_URL:
    # Suntem pe Render (Cloud) -> Folosind PostgreSQL
    # Render dă URL cu "postgres://", dar SQLAlchemy vrea "postgresql://"
    if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
        SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)
else:
    # Suntem pe Laptop (Local) -> Folosim MySQL-ul tău vechi
    # Modifică aici cu parola ta de root de pe laptop dacă vrei să testezi local
    SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:PAROLA_TA@localhost/nume_baza_date"

# Crearea motorului de bază de date
engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()