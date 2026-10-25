from decimal import Decimal, InvalidOperation
from typing import Annotated, Generic, Literal, TypeVar

from pydantic import BaseModel, BeforeValidator, ConfigDict, Field, PlainSerializer


def parse_money(value: object) -> Decimal:
    if not isinstance(value, (str, Decimal)):
        raise ValueError("Use a decimal string, never a float")
    try:
        result = Decimal(value)
        if not result.is_finite() or result != result.quantize(Decimal("0.01")):
            raise ValueError("Expected a finite amount with at most two decimal places")
    except InvalidOperation as exc:
        raise ValueError("Invalid decimal amount") from exc
    return result


Money = Annotated[
    Decimal,
    BeforeValidator(parse_money, json_schema_input_type=str),
    PlainSerializer(lambda value: format(value, ".2f"), return_type=str, when_used="json"),
]
PositiveMoney = Annotated[Money, Field(gt=0, max_digits=12, decimal_places=2)]
Exchange = Literal["HOSE", "HNX", "UPCOM"]
OrderStatus = Literal["PENDING", "PARTIAL", "COMPLETED", "CANCELLED", "REJECTED"]
Symbol = Annotated[str, Field(pattern=r"^[A-Z][A-Z0-9]{0,9}$")]


class ContractModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


T = TypeVar("T")


class Page(ContractModel, Generic[T]):
    items: list[T]
    page: int = Field(ge=1)
    page_size: int = Field(ge=1, le=100)
    total: int = Field(ge=0)


class ErrorDetail(ContractModel):
    code: str
    message: str
    details: dict


class ErrorResponse(ContractModel):
    error: ErrorDetail


ERROR_RESPONSES = {status: {"model": ErrorResponse} for status in (401, 403, 404, 409, 422, 501)}
