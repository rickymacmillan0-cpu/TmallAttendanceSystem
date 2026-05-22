from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class AttendanceDailyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    daily_id: int
    emp_id: int
    emp_no: str
    full_name: str
    dept_name: str
    work_date: date
    shift_id: Optional[int] = None
    first_check_in: Optional[datetime] = None
    last_check_out: Optional[datetime] = None
    work_minutes: Optional[int] = None
    attendance_status: str
    remark: Optional[str] = None
