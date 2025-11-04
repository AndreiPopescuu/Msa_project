from sqlalchemy import Column, Integer, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    sobriety_level = Column(Float, default=1.0)  # 1 = sober, 0 = fully drunk
    updated_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="sessions")
