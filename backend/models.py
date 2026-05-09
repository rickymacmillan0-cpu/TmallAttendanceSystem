"""与 schema.sql 对应的 SQLAlchemy ORM 模型（部分表）。"""

from __future__ import annotations

from datetime import date, datetime, time
from typing import List, Optional

from sqlalchemy import Date, DateTime, ForeignKey, String, Time, UniqueConstraint, text
from sqlalchemy.dialects.mysql import BIGINT, INTEGER
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

UnsignedBigInt = BIGINT(unsigned=True)
UnsignedInt = INTEGER(unsigned=True)


class Department(Base):
    __tablename__ = "department"

    dept_id: Mapped[int] = mapped_column(UnsignedBigInt, primary_key=True, autoincrement=True)
    dept_code: Mapped[str] = mapped_column(String(32), nullable=False, unique=True)
    dept_name: Mapped[str] = mapped_column(String(64), nullable=False)
    parent_dept_id: Mapped[Optional[int]] = mapped_column(
        UnsignedBigInt, ForeignKey("department.dept_id", ondelete="SET NULL", onupdate="CASCADE"), nullable=True
    )
    manager_emp_id: Mapped[Optional[int]] = mapped_column(
        UnsignedBigInt, ForeignKey("employee.emp_id", ondelete="SET NULL", onupdate="CASCADE"), nullable=True
    )
    location: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    parent: Mapped[Optional["Department"]] = relationship(
        remote_side=[dept_id],
        back_populates="children",
        foreign_keys=[parent_dept_id],
    )
    children: Mapped[List["Department"]] = relationship(
        back_populates="parent",
        foreign_keys=[parent_dept_id],
    )
    manager: Mapped[Optional["Employee"]] = relationship(
        back_populates="managed_departments", foreign_keys=[manager_emp_id]
    )
    employees: Mapped[List["Employee"]] = relationship(
        back_populates="department",
        foreign_keys=lambda: [Employee.dept_id],
    )


class JobPosition(Base):
    __tablename__ = "job_position"

    position_id: Mapped[int] = mapped_column(UnsignedBigInt, primary_key=True, autoincrement=True)
    position_code: Mapped[str] = mapped_column(String(32), nullable=False, unique=True)
    position_name: Mapped[str] = mapped_column(String(64), nullable=False)
    job_level: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    employees: Mapped[List["Employee"]] = relationship(
        back_populates="job_position",
        foreign_keys=lambda: [Employee.position_id],
    )


class Employee(Base):
    __tablename__ = "employee"

    emp_id: Mapped[int] = mapped_column(UnsignedBigInt, primary_key=True, autoincrement=True)
    emp_no: Mapped[str] = mapped_column(String(32), nullable=False, unique=True)
    full_name: Mapped[str] = mapped_column(String(64), nullable=False)
    gender: Mapped[Optional[str]] = mapped_column(String(1), nullable=True)
    mobile: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    dept_id: Mapped[int] = mapped_column(
        UnsignedBigInt, ForeignKey("department.dept_id", ondelete="RESTRICT", onupdate="CASCADE"), nullable=False
    )
    position_id: Mapped[int] = mapped_column(
        UnsignedBigInt,
        ForeignKey("job_position.position_id", ondelete="RESTRICT", onupdate="CASCADE"),
        nullable=False,
    )
    hire_date: Mapped[date] = mapped_column(Date, nullable=False)
    work_status: Mapped[str] = mapped_column(String(16), nullable=False, default="ACTIVE")
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    department: Mapped["Department"] = relationship(back_populates="employees", foreign_keys=[dept_id])
    job_position: Mapped["JobPosition"] = relationship(back_populates="employees", foreign_keys=[position_id])
    managed_departments: Mapped[List["Department"]] = relationship(
        back_populates="manager", foreign_keys=[Department.manager_emp_id]
    )
    attendance_daily_rows: Mapped[List["AttendanceDaily"]] = relationship(back_populates="employee")


class WorkShift(Base):
    __tablename__ = "work_shift"

    shift_id: Mapped[int] = mapped_column(UnsignedBigInt, primary_key=True, autoincrement=True)
    shift_code: Mapped[str] = mapped_column(String(32), nullable=False, unique=True)
    shift_name: Mapped[str] = mapped_column(String(64), nullable=False)
    planned_start_time: Mapped[time] = mapped_column(Time, nullable=False)
    planned_end_time: Mapped[time] = mapped_column(Time, nullable=False)
    late_grace_minutes: Mapped[int] = mapped_column(UnsignedInt, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    attendance_daily_rows: Mapped[List["AttendanceDaily"]] = relationship(
        back_populates="shift",
        foreign_keys=lambda: [AttendanceDaily.shift_id],
    )


class AttendanceDaily(Base):
    __tablename__ = "attendance_daily"
    __table_args__ = (UniqueConstraint("emp_id", "work_date", name="uk_daily_emp_date"),)

    daily_id: Mapped[int] = mapped_column(UnsignedBigInt, primary_key=True, autoincrement=True)
    emp_id: Mapped[int] = mapped_column(
        UnsignedBigInt, ForeignKey("employee.emp_id", ondelete="CASCADE", onupdate="CASCADE"), nullable=False
    )
    work_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift_id: Mapped[Optional[int]] = mapped_column(
        UnsignedBigInt, ForeignKey("work_shift.shift_id", ondelete="SET NULL", onupdate="CASCADE"), nullable=True
    )
    first_check_in: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    last_check_out: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    work_minutes: Mapped[Optional[int]] = mapped_column(UnsignedInt, nullable=True)
    attendance_status: Mapped[str] = mapped_column(String(24), nullable=False, default="PENDING")
    remark: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    employee: Mapped["Employee"] = relationship(back_populates="attendance_daily_rows")
    shift: Mapped[Optional["WorkShift"]] = relationship(
        back_populates="attendance_daily_rows", foreign_keys=[shift_id]
    )
