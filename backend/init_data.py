"""临时脚本：向 department / employee 写入示例数据。"""

from __future__ import annotations

from datetime import date

from sqlalchemy import select

from database import SessionLocal
from models import Department, Employee, JobPosition

_POSITION_CODE = "INIT_TECH"
_POSITION_NAME = "工程师"
_DEPT_CODE = "DEPT_TECH"
_DEPT_NAME = "技术部"
_EMP_NO = "EMP_TEST_A"
_EMP_NAME = "测试员A"


def _ensure_job_position(session) -> JobPosition:
    pos = session.scalar(select(JobPosition).where(JobPosition.position_code == _POSITION_CODE))
    if pos is None:
        pos = JobPosition(position_code=_POSITION_CODE, position_name=_POSITION_NAME)
        session.add(pos)
        session.flush()
    return pos


def main() -> None:
    with SessionLocal() as session:
        position = _ensure_job_position(session)

        dept = session.scalar(select(Department).where(Department.dept_code == _DEPT_CODE))
        if dept is None:
            dept = Department(dept_code=_DEPT_CODE, dept_name=_DEPT_NAME)
            session.add(dept)
            session.flush()

        emp = session.scalar(select(Employee).where(Employee.emp_no == _EMP_NO))
        if emp is None:
            session.add(
                Employee(
                    emp_no=_EMP_NO,
                    full_name=_EMP_NAME,
                    dept_id=dept.dept_id,
                    position_id=position.position_id,
                    hire_date=date.today(),
                )
            )

        session.commit()

    print("数据初始化成功")


if __name__ == "__main__":
    main()
