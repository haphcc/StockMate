"""Owner: TV4 - LB. Account selector response for checkpoint 1."""

from pydantic import BaseModel, ConfigDict


class AccountResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    account_id: int
    account_number: str
    account_type: str
    status: str
