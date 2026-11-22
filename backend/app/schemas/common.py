"""Owner: TV4 - LB. Shared API error envelope."""

from decimal import ROUND_HALF_UP, Decimal
from typing import Annotated, Any, Generic, TypeVar

from pydantic import BaseModel, Field, PlainSerializer, WithJsonSchema


def decimal_string(value: Decimal) -> str:
    return format(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP), ".2f")


Money = Annotated[
    Decimal,
    PlainSerializer(decimal_string, return_type=str),
    WithJsonSchema({"type": "string", "pattern": r"^-?[0-9]+\.[0-9]{2}$"}, mode="serialization"),
]
T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    items: list[T]
    page: int
    page_size: int
    total: int


class ErrorBody(BaseModel):
    code: str
    message: str
    details: dict[str, Any] = Field(default_factory=dict)


class ErrorResponse(BaseModel):
    error: ErrorBody
