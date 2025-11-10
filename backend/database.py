from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker

# datele tale de conectare
USERNAME = "root"
PASSWORD = "PopeAndre2213"  # schimbă dacă ai folosit altă parolă
HOST = "localhost"
PORT = "3306"
DATABASE = "drunkmanager"

# URL de conexiune pentru MySQL + SQLAlchemy
DATABASE_URL = f"mysql+pymysql://{USERNAME}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}"

# Creează engine-ul
engine = create_engine(DATABASE_URL, echo=True)

# Creează sesiunea
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Baza pentru modelele ORM
Base = declarative_base()
