"""
データベースの設定とセッション管理。
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from typing import Generator

SQLALCHEMY_DATABASE_URL = "sqlite:///./pomodoro.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency
def get_db() -> Generator:
    """
    データベースセッションを取得するための依存関係（Dependency）関数。
    一連の操作に対するトランザクションスコープを提供します。
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
