from datetime import date, datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class LeaveApplicationCreate(BaseModel):
    """Submit a leave request."""

    emp_id: int = Field(..., description="Applicant employee id")
    leave_type_id: Optional[int] = Field(None, description="Leave type id from leave_type table")
    leave_type_code: Optional[str] = Field(
        None,
        description="Leave type code, e.g. PL (personal). Used when leave_type_id is omitted.",
    )
    start_date: date = Field(..., description="Leave start date (inclusive)")
    end_date: date = Field(..., description="Leave end date (inclusive)")
    reason: str = Field(..., min_length=1, max_length=512)
    attachment_url: Optional[str] = Field(None, max_length=512)

    @field_validator("reason")
    @classmethod
    def reason_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("reason must not be empty")
        return v.strip()

    @model_validator(mode="after")
    def dates_and_type(self) -> "LeaveApplicationCreate":
        if self.end_date < self.start_date:
            raise ValueError("end_date must be on or after start_date")
        if self.leave_type_id is None and not self.leave_type_code:
            self.leave_type_code = "PL"
        if self.leave_type_id is not None and self.leave_type_code:
            raise ValueError("Provide either leave_type_id or leave_type_code, not both")
        return self


class LeaveApplicationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    application_id: int
    emp_id: int
    emp_no: str
    full_name: str
    leave_type_id: int
    leave_type_name: str
    start_at: datetime
    end_at: datetime
    reason: str
    attachment_url: Optional[str] = None
    approval_status: str
    approval_remark: Optional[str] = None
    submitted_at: datetime
    decided_at: Optional[datetime] = None


class LeaveApplicationReview(BaseModel):
    """Approve or reject a leave application."""

    status: Literal["APPROVED", "REJECTED"] = Field(..., description='Use "APPROVED" or "REJECTED"')
    comment: Optional[str] = Field(None, max_length=255, description="Approver remark / rejection reason")

    @field_validator("comment")
    @classmethod
    def comment_strip(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        s = v.strip()
        return s if s else None
