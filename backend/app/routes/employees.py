from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.schemas.employee import EmployeeOut
from models import Employee

router = APIRouter(prefix="/employees", tags=["employees"])


@router.get("", response_model=list[EmployeeOut])
def list_employees(
    dept_id: Optional[int] = Query(None, description="Filter by department id"),
    db: Session = Depends(get_db),
) -> list[EmployeeOut]:
    """List employees; optional dept_id filter. Joins department + job_position via ORM."""
    stmt = (
        select(Employee)
        .options(joinedload(Employee.department), joinedload(Employee.job_position))
        .order_by(Employee.emp_no)
    )
    if dept_id is not None:
        stmt = stmt.where(Employee.dept_id == dept_id)

    employees = db.scalars(stmt).unique().all()
    return [
        EmployeeOut(
            emp_id=e.emp_id,
            emp_no=e.emp_no,
            full_name=e.full_name,
            gender=e.gender,
            mobile=e.mobile,
            email=e.email,
            dept_id=e.dept_id,
            dept_name=e.department.dept_name,
            position_id=e.position_id,
            position_name=e.job_position.position_name,
            hire_date=e.hire_date,
            work_status=e.work_status,
            created_at=e.created_at,
            updated_at=e.updated_at,
        )
        for e in employees
    ]
