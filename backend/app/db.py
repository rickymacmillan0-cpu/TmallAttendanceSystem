"""兼容旧引用：引擎与会话来自项目根目录的 database 模块。"""

from database import SessionLocal, engine, get_db

get_session = get_db
