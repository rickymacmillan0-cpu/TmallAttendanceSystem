# Tmall Attendance System

天猫商城员工考勤管理系统 Demo。当前项目已经实现了一个可运行的请假流程：员工选择、请假申请、我的请假历史、主管待审批列表、同意/驳回审批。

## 项目结构

```text
TmallAttendanceSystem/
├─ backend/              # FastAPI 后端
│  ├─ app/
│  │  ├─ main.py         # API 入口
│  │  ├─ routes/         # 路由：员工、部门、考勤、请假
│  │  └─ schemas/        # Pydantic 数据模型
│  ├─ models.py          # SQLAlchemy ORM 模型
│  ├─ database.py        # 数据库连接
│  ├─ requirements.txt   # Python 依赖
│  └─ .env               # 本地数据库配置
├─ database/             # MySQL 初始化与示例 SQL
│  ├─ init_database.sql
│  ├─ schema.sql
│  ├─ seed.sql
│  ├─ demo_data.sql
│  └─ example_queries.sql
└─ frontend/             # 静态前端页面
   ├─ index.html
   └─ app.js
```

## 环境要求

- Python 3.10+
- MySQL 8.0+
- 浏览器

## 后端配置

后端读取 `backend/.env` 中的数据库配置：

```env
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=你的数据库密码
MYSQL_DATABASE=tmall_attendance
```

如果本机 MySQL 密码不同，先修改 `backend/.env`。

## 安装依赖

在项目根目录执行：

```powershell
cd C:\Users\27926\Desktop\TmallAttendanceSystem\backend
venv\Scripts\pip.exe install -r requirements.txt
```

其中 `cryptography` 是 PyMySQL 连接 MySQL 8 `caching_sha2_password` 认证方式所需依赖。

## 初始化数据库

先确保 MySQL 服务已经启动。

推荐按顺序执行：

```powershell
mysql -u root -p < database\init_database.sql
mysql -u root -p tmall_attendance < database\schema.sql
mysql -u root -p tmall_attendance < database\seed.sql
mysql -u root -p tmall_attendance < database\demo_data.sql
```

如果已经初始化过数据库，可以跳过这一步。

测试数据库连接：

```powershell
cd C:\Users\27926\Desktop\TmallAttendanceSystem\backend
venv\Scripts\python.exe test_db.py
```

成功时会看到：

```text
连接成功！数据库已响应。
```

## 启动后端

打开一个终端，运行：

```powershell
cd C:\Users\27926\Desktop\TmallAttendanceSystem\backend
venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

看到下面内容表示后端启动成功：

```text
Uvicorn running on http://127.0.0.1:8000
```

接口文档：

```text
http://127.0.0.1:8000/docs
```

健康检查：

```text
http://127.0.0.1:8000/health
```

## 启动前端

再打开一个新的终端，运行：

```powershell
cd C:\Users\27926\Desktop\TmallAttendanceSystem\frontend
..\backend\venv\Scripts\python.exe -m http.server 5500
```

浏览器打开：

```text
http://localhost:5500/
```

注意：

- 前端页面地址是 `http://localhost:5500/`
- 后端 API 地址是 `http://127.0.0.1:8000`
- 两个地址不要填反

## 当前可测试流程

1. 打开前端 `http://localhost:5500/`
2. 确认页面顶部 API 地址为 `http://127.0.0.1:8000`
3. 员工下拉框选择员工，或手动输入 `emp_id`
4. 填写开始日期、结束日期、请假类型、事由
5. 点击“提交申请”
6. 在“我的请假历史”查看新申请，状态应为 `PENDING`
7. 在“主管区域”查看待审批列表
8. 点击“同意”或“驳回”
9. 回到“我的请假历史”刷新，状态应变为 `APPROVED` 或 `REJECTED`

当前示例数据中常用员工：

```text
emp_id=1  EMP_TEST_A
emp_id=2  EMP_DEMO_01
emp_id=3  EMP_DEMO_02
emp_id=4  EMP_DEMO_03
```

## 已实现接口

```text
GET    /
GET    /health
GET    /departments
GET    /employees
GET    /attendance/daily
GET    /leave-applications
POST   /leave-applications
PATCH  /leave-applications/{application_id}/review
```

## 常见问题

### 1. 员工下拉框没有内容

先确认后端是否启动：

```text
http://127.0.0.1:8000/health
```

如果打不开，说明后端没有运行，重新启动 uvicorn。

### 2. “我的请假历史”没有内容

可能原因：

- 当前员工没有请假记录
- API 地址填错了
- 后端没有启动

可以先用 `emp_id=1` 测试，因为示例数据中它有请假记录。

### 3. 前端能打开，但按钮没反应

按 `Ctrl + F5` 强制刷新，避免浏览器缓存旧的 `app.js`。

### 4. 数据库连接报 cryptography 缺失

执行：

```powershell
cd C:\Users\27926\Desktop\TmallAttendanceSystem\backend
venv\Scripts\pip.exe install cryptography
```

### 5. 中文显示乱码

数据库和连接应使用 `utf8mb4`。当前 SQL 脚本中已经设置：

```sql
SET NAMES utf8mb4;
```

如果终端里显示乱码，优先以浏览器和数据库实际内容为准。

## 下一步开发建议

- 整理前端页面交互和提示
- 补充考勤打卡页面
- 增加员工管理功能
- 增加登录与权限控制
- 增加自动化测试
