"""
データベースの設定とセッション管理。
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from typing import Generator
from dotenv import load_dotenv

# .envファイルがあれば読み込む
load_dotenv()

# Renderなどで設定される DATABASE_URL を優先し、無ければローカルのSQLiteを使う
SQLALCHEMY_DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./pomodoro.db")

# SQLAlchemy 1.4以降、URLは "postgresql://" で始まる必要があるための対応
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

# SQLiteの場合はcheck_same_threadが必要だが、PostgreSQLの場合は不要
connect_args = {"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args=connect_args
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
