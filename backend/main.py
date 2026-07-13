from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import date, timedelta, datetime
from typing import List
from zoneinfo import ZoneInfo

import models, schemas
from database import engine, get_db, SessionLocal

# -------------------------------------------------------------------
# アプリケーションの初期設定
# -------------------------------------------------------------------

# データベースのテーブルを作成（存在しない場合のみ）
models.Base.metadata.create_all(bind=engine)

# デフォルトプリセットの初期化
db = SessionLocal()
try:
    if db.query(models.TimerPreset).count() == 0:
        defaults = [
            models.TimerPreset(name="学習", focus_minutes=50, break_minutes=10),
            models.TimerPreset(name="ポモドーロ", focus_minutes=25, break_minutes=5),
            models.TimerPreset(name="ショート", focus_minutes=15, break_minutes=5)
        ]
        db.add_all(defaults)
        db.commit()
finally:
    db.close()

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
    today = datetime.now(ZoneInfo("Asia/Tokyo")).date()
    
    # 今日の記録のみをフィルタリング
    records = db.query(models.PomodoroRecord).filter(models.PomodoroRecord.date == today).all()
    
    # 集中時間の合計を計算
    total_minutes = sum(record.duration_minutes for record in records)
    
    return schemas.StatsResponse(date=today, total_duration_minutes=total_minutes)

@app.get(
    "/stats/weekly",
    response_model=List[schemas.StatsResponse],
    summary="過去7日間の統計データの取得",
    response_description="過去7日間の日別合計集中時間のリスト"
)
def get_weekly_stats(db: Session = Depends(get_db)) -> List[schemas.StatsResponse]:
    """
    今週（日曜日から土曜日）の記録を集計し、日ごとの合計集中時間（分）のリストを返す。
    ウィジェットのグラフ表示に使用される。
    """
    today = datetime.now(ZoneInfo("Asia/Tokyo")).date()
    # isoweekday()は月曜が1、日曜が7。日曜始まりにするため、日曜なら0日前、月曜なら1日前...戻る
    days_to_subtract = today.isoweekday() % 7
    start_date = today - timedelta(days=days_to_subtract)
    end_date = start_date + timedelta(days=6)
    
    # 今週1週間の記録をまとめて取得
    records = db.query(models.PomodoroRecord).filter(
        models.PomodoroRecord.date >= start_date,
        models.PomodoroRecord.date <= end_date
    ).all()
    
    # 日付ごとの集計用辞書を初期化（0で埋める）
    stats_dict = {start_date + timedelta(days=i): 0 for i in range(7)}
    
    # 記録を集計
    for record in records:
        if record.date in stats_dict:
            stats_dict[record.date] += record.duration_minutes
            
    # レスポンス形式に変換（日付順）
    result = [
        schemas.StatsResponse(date=d, total_duration_minutes=mins)
        for d, mins in sorted(stats_dict.items())
    ]
    
    return result

@app.get(
    "/stats/timeline",
    response_model=List[schemas.RecordResponse],
    summary="今日の詳細タイムラインデータの取得",
    response_description="朝8時起点の24時間以内に記録されたセッションのリスト"
)
def get_today_timeline(db: Session = Depends(get_db)) -> List[schemas.RecordResponse]:
    """
    朝8:00を起点とした1日（8:00〜翌朝7:59）のセッション記録を返す。
    タイムライングラフの描画に使用される。
    """
    now = datetime.now(ZoneInfo("Asia/Tokyo"))
    if now.hour < 8:
        # 現在時刻が深夜0:00〜7:59の場合、前日の8:00から今日の7:59まで
        start_time = now.replace(hour=8, minute=0, second=0, microsecond=0) - timedelta(days=1)
    else:
        # 現在時刻が朝8:00以降の場合、今日の8:00から翌日の7:59まで
        start_time = now.replace(hour=8, minute=0, second=0, microsecond=0)
    
    end_time = start_time + timedelta(hours=24)
    
    records = db.query(models.PomodoroRecord).filter(
        models.PomodoroRecord.created_at >= start_time,
        models.PomodoroRecord.created_at < end_time
    ).all()
    
    return records

# -------------------------------------------------------------------
# プリセット用エンドポイント
# -------------------------------------------------------------------

@app.get(
    "/presets/",
    response_model=List[schemas.PresetResponse],
    summary="プリセット一覧の取得",
    response_description="保存されているプリセットのリスト"
)
def read_presets(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> List[schemas.PresetResponse]:
    """
    データベースに保存されているすべてのプリセットを取得する。
    """
    return db.query(models.TimerPreset).offset(skip).limit(limit).all()


@app.post(
    "/presets/",
    response_model=schemas.PresetResponse,
    summary="プリセットの作成",
    response_description="保存されたプリセットのデータ"
)
def create_preset(preset: schemas.PresetCreate, db: Session = Depends(get_db)) -> schemas.PresetResponse:
    """
    新しいプリセットを作成してデータベースに保存する。
    """
    db_preset = models.TimerPreset(**preset.dict())
    db.add(db_preset)
    db.commit()
    db.refresh(db_preset)
    return db_preset


@app.delete(
    "/presets/{preset_id}",
    summary="プリセットの削除",
    response_description="削除成功のメッセージ"
)
def delete_preset(preset_id: int, db: Session = Depends(get_db)):
    """
    指定されたIDのプリセットを削除する。
    """
    db_preset = db.query(models.TimerPreset).filter(models.TimerPreset.id == preset_id).first()
    if db_preset:
        db.delete(db_preset)
        db.commit()
    return {"message": "Preset deleted successfully"}