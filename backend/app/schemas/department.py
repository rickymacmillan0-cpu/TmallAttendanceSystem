from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class DepartmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    dept_id: int
    dept_code: str
    dept_name: str
    parent_dept_id: Optional[int] = None
    manager_emp_id: Optional[int] = None
    location: Optional[str] = None
    created_at: datetime
    updated_at: datetime
