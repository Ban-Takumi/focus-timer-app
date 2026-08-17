"""
Pomodoro Timer API アプリケーションエントリーポイント。
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI

import models
from database import engine, SessionLocal
from routers import records, presets, stats


def init_db():
    """データベースの初期化とデフォルトプリセットの投入。"""
    models.Base.metadata.create_all(bind=engine)
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    """アプリケーションの起動・終了ライフサイクルイベント。"""
    # 起動時処理
    init_db()
    yield
    # 終了時処理（必要に応じてリソース解放など）


app = FastAPI(
    title="Pomodoro Timer API",
    description="ポモドーロ・タイマーの記録と統計を管理するバックエンドAPI",
    version="1.0.0",
    lifespan=lifespan
)

# ルーターの登録
app.include_router(records.router)
app.include_router(presets.router)
app.include_router(stats.router)


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