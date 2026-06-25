"""
Pomodoro Timer アプリケーションのデータベースモデル。
"""
from sqlalchemy import Column, Integer, String, Date, DateTime
from sqlalchemy.sql import func
from database import Base

class PomodoroRecord(Base):
    """
    データベース内の単一のポモドーロセッション記録を表します。
    """
    __tablename__ = "records"

    id = Column(Integer, primary_key=True, index=True)
    task_name = Column(String, index=True)
    duration_minutes = Column(Integer)
    date = Column(Date, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
