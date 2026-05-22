from datetime import datetime, time
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.schemas.leave import LeaveApplicationCreate, LeaveApplicationOut, LeaveApplicationReview
from models import Employee, LeaveApplication, LeaveType

router = APIRouter(prefix="/leave-applications", tags=["leave-applications"])

_ALLOWED_APPROVAL_STATUSES = frozenset({"PENDING", "APPROVED", "REJECTED", "CANCELLED"})

_WORK_START = time(9, 0, 0)
_WORK_END = time(18, 0, 0)


def _leave_application_to_out(application: LeaveApplication) -> LeaveApplicationOut:
    return LeaveApplicationOut(
        application_id=application.application_id,
        emp_id=application.emp_id,
        emp_no=application.employee.emp_no,
        full_name=application.employee.full_name,
        leave_type_id=application.leave_type_id,
        leave_type_name=application.leave_type.type_name,
        start_at=application.start_at,
        end_at=application.end_at,
        reason=application.reason,
        attachment_url=application.attachment_url,
        approval_status=application.approval_status,
        approval_remark=application.approval_remark,
        submitted_at=application.submitted_at,
        decided_at=application.decided_at,
    )


def _load_leave_application(db: Session, application_id: int) -> LeaveApplication | None:
    return db.scalar(
        select(LeaveApplication)
        .options(
            joinedload(LeaveApplication.employee),
            joinedload(LeaveApplication.leave_type),
        )
        .where(LeaveApplication.application_id == application_id)
    )


def _date_range_to_datetimes(start_date, end_date) -> tuple[datetime, datetime]:
    start_at = datetime.combine(start_date, _WORK_START)
    end_at = datetime.combine(end_date, _WORK_END)
    return start_at, end_at


@router.get("", response_model=list[LeaveApplicationOut])
def list_leave_applications(
    emp_id: Optional[int] = Query(None, description="Applicant employee id — 该员工的请假历史"),
    approval_status: Optional[str] = Query(
        None,
        description="PENDING / APPROVED / REJECTED / CANCELLED — 如 PENDING 可查看待审批列表",
    ),
    dept_id: Optional[int] = Query(
        None,
        description="按申请人所在部门筛选 — 可与 approval_status=PENDING 组合供主管查看本部门待审",
    ),
    limit: int = Query(100, ge=1, le=500, description="Max rows to return"),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
) -> list[LeaveApplicationOut]:
    """List leave applications: employee history (emp_id), supervisor queue (approval_status, optional dept_id)."""
    if approval_status is not None and approval_status not in _ALLOWED_APPROVAL_STATUSES:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid approval_status. Allowed: {', '.join(sorted(_ALLOWED_APPROVAL_STATUSES))}",
        )

    stmt = (
        select(LeaveApplication)
        .options(
            joinedload(LeaveApplication.employee),
            joinedload(LeaveApplication.leave_type),
        )
        .order_by(LeaveApplication.submitted_at.desc())
    )
    if dept_id is not None:
        stmt = stmt.join(Employee, Employee.emp_id == LeaveApplication.emp_id).where(Employee.dept_id == dept_id)
    if emp_id is not None:
        stmt = stmt.where(LeaveApplication.emp_id == emp_id)
    if approval_status is not None:
        stmt = stmt.where(LeaveApplication.approval_status == approval_status)

    stmt = stmt.offset(offset).limit(limit)
    rows = db.scalars(stmt).unique().all()
    return [_leave_application_to_out(r) for r in rows]


@router.post("", response_model=LeaveApplicationOut, status_code=status.HTTP_201_CREATED)
def create_leave_application(
    body: LeaveApplicationCreate,
    db: Session = Depends(get_db),
) -> LeaveApplicationOut:
    employee = db.get(Employee, body.emp_id)
    if employee is None:
        raise HTTPException(status_code=404, detail=f"Employee emp_id={body.emp_id} not found")

    if body.leave_type_id is not None:
        leave_type = db.get(LeaveType, body.leave_type_id)
    else:
        leave_type = db.scalar(
            select(LeaveType).where(LeaveType.type_code == body.leave_type_code)
        )
    if leave_type is None:
        raise HTTPException(
            status_code=404,
            detail="Leave type not found. Run database/seed.sql or pass a valid leave_type_id.",
        )

    start_at, end_at = _date_range_to_datetimes(body.start_date, body.end_date)

    application = LeaveApplication(
        emp_id=body.emp_id,
        leave_type_id=leave_type.leave_type_id,
        start_at=start_at,
        end_at=end_at,
        reason=body.reason,
        attachment_url=body.attachment_url,
        approval_status="PENDING",
    )
    db.add(application)
    db.commit()
    db.refresh(application)

    application = _load_leave_application(db, application.application_id)
    assert application is not None

    return _leave_application_to_out(application)


@router.patch("/{application_id}/review", response_model=LeaveApplicationOut)
def review_leave_application(
    application_id: int,
    body: LeaveApplicationReview,
    db: Session = Depends(get_db),
) -> LeaveApplicationOut:
    application = _load_leave_application(db, application_id)
    if application is None:
        raise HTTPException(status_code=404, detail=f"Leave application id={application_id} not found")

    if application.approval_status != "PENDING":
        raise HTTPException(
            status_code=409,
            detail=f"Leave application is not pending (current status: {application.approval_status})",
        )

    application.approval_status = body.status
    application.approval_remark = body.comment
    application.decided_at = datetime.now()

    db.add(application)
    db.commit()

    application = _load_leave_application(db, application_id)
    assert application is not None
    return _leave_application_to_out(application)
