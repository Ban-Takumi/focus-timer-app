from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import date
from typing import List

import models, schemas
from database import engine, get_db

# -------------------------------------------------------------------
# アプリケーションの初期設定
# -------------------------------------------------------------------

# データベースのテーブルを作成（存在しない場合のみ）
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Pomodoro Timer API",
    description="ポモドーロ・タイマーの記録と統計を管理するバックエンドAPI",
    version="1.0.0"
)

# -------------------------------------------------------------------
# API エンドポイント
# -------------------------------------------------------------------

@app.get(
    "/",
    summary="サーバーの稼働確認",
    response_description="サーバーの起動状態を示すメッセージ"
)
def read_root() -> dict:
    """
    サーバーが正常に起動しているかを確認するためのヘルスチェック用API。
    """
    return {"message": "Pomodoro Timer API is running!"}


@app.post(
    "/records/",
    response_model=schemas.RecordResponse,
    summary="ポモドーロ記録の保存",
    response_description="保存された記録の詳細データ"
)
def create_record(record: schemas.RecordCreate, db: Session = Depends(get_db)) -> schemas.RecordResponse:
    """
    タイマー終了時に新しいポモドーロの記録をデータベースに保存する。
    """
    # スキーマ（入力データ）からDBモデルへ変換
    db_record = models.PomodoroRecord(**record.dict())
    
    # データベースへの書き込み処理
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    
    return db_record


@app.get(
    "/records/",
    response_model=List[schemas.RecordResponse],
    summary="記録一覧の取得（デバッグ用）",
    response_description="保存されている記録のリスト"
)
def read_records(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> List[schemas.RecordResponse]:
    """
    データベースに保存されているすべての記録を取得する（ページネーション対応）。
    """
    records = db.query(models.PomodoroRecord).offset(skip).limit(limit).all()
    return records


@app.get(
    "/stats/today",
    response_model=schemas.StatsResponse,
    summary="今日の統計データの取得",
    response_description="今日の合計集中時間と日付"
)
def get_today_stats(db: Session = Depends(get_db)) -> schemas.StatsResponse:
    """
    今日の日付に一致する記録を集計し、合計の集中時間（分）を計算して返す。
    ウィジェットでのデータ表示に使用される。
    """
    today = date.today()
    
    # 今日の記録のみをフィルタリング
    records = db.query(models.PomodoroRecord).filter(models.PomodoroRecord.date == today).all()
    
    # 集中時間の合計を計算
    total_minutes = sum(record.duration_minutes for record in records)
    
    return schemas.StatsResponse(date=today, total_duration_minutes=total_minutes)