from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.schemas.department import DepartmentOut
from models import Department

router = APIRouter(prefix="/departments", tags=["departments"])


@router.get("", response_model=list[DepartmentOut])
def list_departments(db: Session = Depends(get_db)) -> list[DepartmentOut]:
    rows = db.scalars(select(Department).order_by(Department.dept_code)).all()
    return [DepartmentOut.model_validate(row) for row in rows]
