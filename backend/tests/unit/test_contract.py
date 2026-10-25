import json
from decimal import Decimal
from pathlib import Path

import pytest
from pydantic import TypeAdapter, ValidationError

from app.schemas.accounts import AccountResponse, AssetResponse, PortfolioResponse
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from app.schemas.common import Money
from app.schemas.market import CandleResponse, StockResponse
from app.schemas.notifications import NotificationResponse
from app.schemas.trading import CreateOrderRequest, OrderResponse, TransactionResponse
from app.schemas.watchlist import WatchlistResponse

ROOT = Path(__file__).resolve().parents[3]


@pytest.mark.parametrize(
    "name,model",
    [
        ("register", RegisterRequest),
        ("login", LoginRequest),
        ("user", UserResponse),
        ("account", AccountResponse),
        ("assets", AssetResponse),
        ("stock", StockResponse),
        ("portfolio", PortfolioResponse),
        ("order", OrderResponse),
        ("transaction", TransactionResponse),
        ("token", TokenResponse),
        ("candle", CandleResponse),
        ("watchlist", WatchlistResponse),
        ("notification", NotificationResponse),
    ],
)
def test_handoff_examples_match_api_models(name, model):
    examples = json.loads((ROOT / "docs/contracts/examples.json").read_text(encoding="utf-8"))
    parsed = model.model_validate(examples[name])
    # Serialization must remain valid input, including exact money and timezone fields.
    assert model.model_validate_json(parsed.model_dump_json()) == parsed


def test_money_roundtrip_preserves_cents_and_large_values():
    adapter = TypeAdapter(Money)
    for value in ("1000000000.01", "999999999999999999.99", "-4500000.25", "0.00"):
        result = adapter.validate_json(json.dumps(value))
        assert result == Decimal(value)
        assert json.loads(adapter.dump_json(result)) == value


@pytest.mark.parametrize("value", [1, 1.01, True, "NaN", "Infinity", "1.001", None])
def test_money_rejects_lossy_or_invalid_values(value):
    with pytest.raises(ValidationError):
        TypeAdapter(Money).validate_python(value)


def test_order_example_matches_contract():
    examples = json.loads((ROOT / "docs/contracts/examples.json").read_text(encoding="utf-8"))
    order = CreateOrderRequest.model_validate(examples["create_order"])
    assert order.quantity == 100
    assert order.order_price == Decimal("100000.00")


@pytest.mark.parametrize("quantity", [0, -100, 99, 150, 100.0, "100", True])
def test_order_rejects_non_integer_or_non_round_lots(quantity):
    with pytest.raises(ValidationError):
        CreateOrderRequest(
            client_order_id="12345678-1234-4234-8234-123456789abc",
            stock_symbol="FPT",
            order_type="BUY",
            quantity=quantity,
            order_price="100000.00",
        )
