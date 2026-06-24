from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import date
from typing import List

import models, schemas
from database import engine, get_db

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pomodoro Timer API")

@app.get("/")
def read_root():
    return {"message": "Pomodoro Timer API is running!"}

@app.post("/records/", response_model=schemas.RecordResponse)
def create_record(record: schemas.RecordCreate, db: Session = Depends(get_db)):
    db_record = models.PomodoroRecord(**record.dict())
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

@app.get("/records/", response_model=List[schemas.RecordResponse])
def read_records(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    records = db.query(models.PomodoroRecord).offset(skip).limit(limit).all()
    return records

@app.get("/stats/today", response_model=schemas.StatsResponse)
def get_today_stats(db: Session = Depends(get_db)):
    today = date.today()
    records = db.query(models.PomodoroRecord).filter(models.PomodoroRecord.date == today).all()
    total_minutes = sum(record.duration_minutes for record in records)
    return schemas.StatsResponse(date=today, total_duration_minutes=total_minutes)