from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.schemas.attendance import AttendanceDailyOut
from models import AttendanceDaily, Employee

router = APIRouter(prefix="/attendance", tags=["attendance"])


@router.get("/daily", response_model=list[AttendanceDailyOut])
def list_attendance_daily(
    work_date: date = Query(..., description="Attendance work date, e.g. 2026-05-06"),
    dept_id: Optional[int] = Query(None, description="Optional filter by department id"),
    db: Session = Depends(get_db),
) -> list[AttendanceDailyOut]:
    stmt = (
        select(AttendanceDaily)
        .options(joinedload(AttendanceDaily.employee).joinedload(Employee.department))
        .where(AttendanceDaily.work_date == work_date)
    )
    if dept_id is not None:
        stmt = stmt.join(AttendanceDaily.employee).where(Employee.dept_id == dept_id)

    rows = db.scalars(stmt).unique().all()
    rows.sort(key=lambda r: r.employee.emp_no)

    return [
        AttendanceDailyOut(
            daily_id=r.daily_id,
            emp_id=r.emp_id,
            emp_no=r.employee.emp_no,
            full_name=r.employee.full_name,
            dept_name=r.employee.department.dept_name,
            work_date=r.work_date,
            shift_id=r.shift_id,
            first_check_in=r.first_check_in,
            last_check_out=r.last_check_out,
            work_minutes=r.work_minutes,
            attendance_status=r.attendance_status,
            remark=r.remark,
        )
        for r in rows
    ]
