from pydantic import BaseModel
from datetime import date, datetime

class RecordCreate(BaseModel):
    task_name: str
    duration_minutes: int
    date: date

class RecordResponse(BaseModel):
    id: int
    task_name: str
    duration_minutes: int
    date: date
    created_at: datetime

    class Config:
        orm_mode = True
        from_attributes = True

class StatsResponse(BaseModel):
    date: date
    total_duration_minutes: int
