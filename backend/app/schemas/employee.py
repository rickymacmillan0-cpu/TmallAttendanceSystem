from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class EmployeeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    emp_id: int
    emp_no: str
    full_name: str
    gender: Optional[str] = None
    mobile: Optional[str] = None
    email: Optional[str] = None
    dept_id: int
    dept_name: str
    position_id: int
    position_name: str
    hire_date: date
    work_status: str
    created_at: datetime
    updated_at: datetime
