"""FastAPI application entry."""

import traceback

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.config import settings
from app.db import SessionLocal
from app.routes import attendance, departments, employees, leave_applications

app = FastAPI(
    title="Tmall Attendance API",
    description="天猫商城员工考勤管理系统 - 后端 API",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(departments.router)
app.include_router(employees.router)
app.include_router(attendance.router)
app.include_router(leave_applications.router)


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Tmall Attendance API", "docs": "/docs"}


@app.get("/health")
def health() -> dict[str, str]:
    """Check MySQL connectivity (uses .env in backend/)."""
    with SessionLocal() as session:
        session.execute(text("SELECT 1"))
    return {"status": "ok", "database": settings.mysql_database}


@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_error_handler(_request: Request, exc: SQLAlchemyError) -> JSONResponse:
    """Show DB errors in Swagger response body when DEBUG=true."""
    content: dict = {"detail": f"Database error: {exc}"}
    if settings.debug:
        content["traceback"] = traceback.format_exc()
    return JSONResponse(status_code=500, content=content)

