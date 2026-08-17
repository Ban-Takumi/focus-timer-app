"""
ポモドーロ記録に関するAPIルーター。
"""
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

import models, schemas
from database import get_db

router = APIRouter(prefix="/records", tags=["records"])


@router.post(
    "/",
    response_model=schemas.RecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="ポモドーロ記録の保存",
    response_description="保存された記録の詳細データ"
)
def create_record(
    record: schemas.RecordCreate,
    db: Session = Depends(get_db)
) -> schemas.RecordResponse:
    """
    タイマー終了時に新しいポモドーロの記録をデータベースに保存する。
    """
    db_record = models.PomodoroRecord(**record.model_dump())
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record


@router.get(
    "/",
    response_model=List[schemas.RecordResponse],
    summary="記録一覧の取得（デバッグ用）",
    response_description="保存されている記録のリスト"
)
def read_records(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
) -> List[schemas.RecordResponse]:
    """
    データベースに保存されているすべての記録を取得する（ページネーション対応）。
    """
    return db.query(models.PomodoroRecord).offset(skip).limit(limit).all()
