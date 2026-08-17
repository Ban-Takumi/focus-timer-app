"""
統計データに関するAPIルーター。
"""
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

import schemas
from database import get_db
from services import stats_service

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get(
    "/today",
    response_model=schemas.StatsResponse,
    summary="今日の統計データの取得",
    response_description="今日の合計集中時間と日付"
)
def get_today_stats(db: Session = Depends(get_db)) -> schemas.StatsResponse:
    """
    今日の日付に一致する記録を集計し、合計の集中時間（分）を計算して返す。
    ウィジェットでのデータ表示に使用される。
    """
    return stats_service.get_today_stats(db)


@router.get(
    "/weekly",
    response_model=List[schemas.StatsResponse],
    summary="過去7日間の統計データの取得",
    response_description="過去7日間の日別合計集中時間のリスト"
)
def get_weekly_stats(db: Session = Depends(get_db)) -> List[schemas.StatsResponse]:
    """
    今週（日曜日から土曜日）の記録を集計し、日ごとの合計集中時間（分）のリストを返す。
    ウィジェットのグラフ表示に使用される。
    """
    return stats_service.get_weekly_stats(db)


@router.get(
    "/timeline",
    response_model=List[schemas.RecordResponse],
    summary="今日の詳細タイムラインデータの取得",
    response_description="朝8時起点の24時間以内に記録されたセッションのリスト"
)
def get_today_timeline(db: Session = Depends(get_db)) -> List[schemas.RecordResponse]:
    """
    朝8:00を起点とした1日（8:00〜翌朝7:59）のセッション記録を返す。
    タイムライングラフの描画に使用される。
    """
    return stats_service.get_today_timeline_records(db)
