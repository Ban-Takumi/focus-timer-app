"""
タイマープリセットに関するAPIルーター。
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

import models, schemas
from database import get_db

router = APIRouter(prefix="/presets", tags=["presets"])


@router.get(
    "/",
    response_model=List[schemas.PresetResponse],
    summary="プリセット一覧の取得",
    response_description="保存されているプリセットのリスト"
)
def read_presets(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
) -> List[schemas.PresetResponse]:
    """
    データベースに保存されているすべてのプリセットを取得する。
    """
    return db.query(models.TimerPreset).offset(skip).limit(limit).all()


@router.post(
    "/",
    response_model=schemas.PresetResponse,
    status_code=status.HTTP_201_CREATED,
    summary="プリセットの作成",
    response_description="保存されたプリセットのデータ"
)
def create_preset(
    preset: schemas.PresetCreate,
    db: Session = Depends(get_db)
) -> schemas.PresetResponse:
    """
    新しいプリセットを作成してデータベースに保存する。
    """
    db_preset = models.TimerPreset(**preset.model_dump())
    db.add(db_preset)
    db.commit()
    db.refresh(db_preset)
    return db_preset


@router.delete(
    "/{preset_id}",
    summary="プリセットの削除",
    response_description="削除成功のメッセージ"
)
def delete_preset(
    preset_id: int,
    db: Session = Depends(get_db)
) -> dict:
    """
    指定されたIDのプリセットを削除する。
    """
    db_preset = db.query(models.TimerPreset).filter(models.TimerPreset.id == preset_id).first()
    if not db_preset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Preset not found")
    
    db.delete(db_preset)
    db.commit()
    return {"message": "Preset deleted successfully"}
