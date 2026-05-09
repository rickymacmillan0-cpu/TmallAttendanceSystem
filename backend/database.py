"""数据库引擎与 SQLAlchemy Session 管理。"""

from collections.abc import Generator
from urllib.parse import quote_plus

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings


def _database_url() -> str:
    user = quote_plus(settings.mysql_user)
    password = quote_plus(settings.mysql_password)
    return (
        f"mysql+pymysql://{user}:{password}"
        f"@{settings.mysql_host}:{settings.mysql_port}/{settings.mysql_database}"
        "?charset=utf8mb4"
    )


class Base(DeclarativeBase):
    """ORM 模型基类。"""


engine = create_engine(_database_url(), pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    """Web 框架依赖注入：一次请求一个会话，用完关闭。"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
