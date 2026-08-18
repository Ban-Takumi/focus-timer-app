import random
from datetime import datetime, timedelta, timezone
from database import SessionLocal
from models import PomodoroRecord

def seed_dummy_data():
    db = SessionLocal()
    
    # 既存のデータをリセット（前回のダミーデータを消去）
    db.query(PomodoroRecord).delete()
    db.commit() # 一度確定
    
    tasks = ["API設計", "SwiftUIリファクタリング", "WidgetKit調査", "面接準備", "ポートフォリオ作成", "コードレビュー", "メール返信", "読書"]
    
    today = datetime.now(timezone.utc).date()
    total_inserted = 0
    
    print("⏳ ダミーデータを生成中...")
    
    # 日曜日〜土曜日まで全て埋まるように、過去7日分 + 未来4日分（今週の残り）を生成
    for i in range(-7, 5):
        target_date = today + timedelta(days=i)
        
        # 今日のデータだけ意図的に多く（10〜14回）してタイムラインを賑やかにする
        if target_date == today:
            pomodoro_count = random.randint(10, 14)
        else:
            pomodoro_count = random.randint(4, 8)
        
        for j in range(pomodoro_count):
            task_name = random.choice(tasks)
            duration = 25
            
            # Macアプリ側で+9時間(JST)されることを考慮。
            # タイムラインが横に広く埋まるよう、UTCとして 0時〜14時 (JSTで9時〜23時) を生成
            hour = random.randint(0, 14)
            minute = random.randint(0, 59)
            
            created_at = datetime(
                year=target_date.year, 
                month=target_date.month, 
                day=target_date.day,
                hour=hour,
                minute=minute,
                tzinfo=timezone.utc # UTCとして明示
            )
            
            record = PomodoroRecord(
                task_name=task_name,
                duration_minutes=duration,
                date=target_date,
                created_at=created_at
            )
            db.add(record)
            total_inserted += 1
            
    db.commit()
    db.close()
    
    print(f"✅ 古いデータを削除し、新しく {total_inserted} 件のダミーデータを追加しました！")

if __name__ == "__main__":
    seed_dummy_data()
