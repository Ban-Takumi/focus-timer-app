"""
データ検証とシリアライズのためのPydanticスキーマ。
"""
from pydantic import BaseModel
from datetime import date, datetime

class RecordCreate(BaseModel):
    """新しいポモドーロ記録を作成するためのスキーマ。"""
    task_name: str
    duration_minutes: int
    date: date

class RecordResponse(BaseModel):
    """APIレスポンスでポモドーロ記録を返すためのスキーマ。"""
    id: int
    task_name: str
    duration_minutes: int
    date: date
    created_at: datetime

    class Config:
        from_attributes = True

class StatsResponse(BaseModel):
    """日別統計情報を返すためのスキーマ。"""
    date: date
    total_duration_minutes: int

class PresetCreate(BaseModel):
    """新しいプリセットを作成するためのスキーマ。"""
    name: str
    focus_minutes: int
    break_minutes: int

class PresetResponse(BaseModel):
    """APIレスポンスでプリセットを返すためのスキーマ。"""
    id: int
    name: str
    focus_minutes: int
    break_minutes: int
    created_at: datetime

    class Config:
        from_attributes = True
