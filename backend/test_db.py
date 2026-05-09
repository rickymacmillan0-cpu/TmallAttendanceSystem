from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

# 1. 加载环境变量
load_dotenv()

# 2. 构建连接字符串 (注意根据你.env里的变量名调整)
db_url = f"mysql+pymysql://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}@{os.getenv('MYSQL_HOST')}:{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DATABASE')}"

# 3. 创建引擎
engine = create_engine(db_url)

# 4. 尝试执行一条最简单的指令
try:
    with engine.connect() as connection:
        result = connection.execute(text("SELECT 1"))
        print("连接成功！数据库已响应。")
except Exception as e:
    print(f"连接失败，错误原因是: {e}")