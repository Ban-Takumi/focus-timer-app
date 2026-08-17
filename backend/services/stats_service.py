"""
統計・タイムライン計算に関するビジネスロジック。
"""
from datetime import date, datetime, timedelta
from typing import List, Tuple
from zoneinfo import ZoneInfo
from sqlalchemy.orm import Session

import models, schemas

JST = ZoneInfo("Asia/Tokyo")
UTC = ZoneInfo("UTC")


def get_current_jst_datetime() -> datetime:
    """現在の日本標準時 (JST) を取得する。"""
    return datetime.now(JST)


def get_today_stats(db: Session) -> schemas.StatsResponse:
    """
    今日（JST基準）の合計集中時間を計算して返す。
    """
    today = get_current_jst_datetime().date()
    records = db.query(models.PomodoroRecord).filter(models.PomodoroRecord.date == today).all()
    total_minutes = sum(record.duration_minutes for record in records)
    return schemas.StatsResponse(date=today, total_duration_minutes=total_minutes)


def get_weekly_stats(db: Session) -> List[schemas.StatsResponse]:
    """
    今週（日曜日から土曜日）の日別合計集中時間リストを返す。
    """
    today = get_current_jst_datetime().date()
    # 日曜始まりにするため、日曜なら0日前、月曜なら1日前...戻る (isoweekday: 月=1...日=7)
    days_to_subtract = today.isoweekday() % 7
    start_date = today - timedelta(days=days_to_subtract)
    end_date = start_date + timedelta(days=6)

    # 1週間の記録を取得
    records = db.query(models.PomodoroRecord).filter(
        models.PomodoroRecord.date >= start_date,
        models.PomodoroRecord.date <= end_date
    ).all()

    # 日付ごとの集計用辞書を0分で初期化
    stats_dict = {start_date + timedelta(days=i): 0 for i in range(7)}

    for record in records:
        if record.date in stats_dict:
            stats_dict[record.date] += record.duration_minutes

    return [
        schemas.StatsResponse(date=d, total_duration_minutes=mins)
        for d, mins in sorted(stats_dict.items())
    ]


def get_timeline_range() -> Tuple[datetime, datetime]:
    """
    タイムラインの集計範囲（朝8:00起点の24時間）を計算して返す (JST)。
    """
    now = get_current_jst_datetime()
    if now.hour < 8:
        # 深夜0:00〜7:59の場合、前日8:00起点
        start_time = now.replace(hour=8, minute=0, second=0, microsecond=0) - timedelta(days=1)
    else:
        # 朝8:00以降の場合、当日8:00起点
        start_time = now.replace(hour=8, minute=0, second=0, microsecond=0)
    
    end_time = start_time + timedelta(hours=24)
    return start_time, end_time


def get_today_timeline_records(db: Session) -> List[models.PomodoroRecord]:
    """
    朝8:00起点の24時間以内に記録されたセッションのリストを取得する。
    SQLite (UTC naive) と PostgreSQL (TIMESTAMP WITH TIMEZONE) の両方に対応。
    """
    start_time, end_time = get_timeline_range()
    
    # SQLite の場合は UTC naive datetime に変換して比較
    if db.bind and db.bind.dialect.name == "sqlite":
        start_query = start_time.astimezone(UTC).replace(tzinfo=None)
        end_query = end_time.astimezone(UTC).replace(tzinfo=None)
    else:
        start_query = start_time
        end_query = end_time

    return db.query(models.PomodoroRecord).filter(
        models.PomodoroRecord.created_at >= start_query,
        models.PomodoroRecord.created_at < end_query
    ).all()
