"""Published fixture compatibility and Decimal rounding at the serialization boundary."""

import json
from decimal import Decimal
from pathlib import Path

import pytest

from app.schemas.accounts import AssetResponse, PortfolioResponse
from app.schemas.common import decimal_string
from app.schemas.market import CandleResponse, StockResponse
from app.schemas.watchlist import WatchlistResponse


@pytest.mark.parametrize(
    "value,expected",
    [
        ("1.005", "1.01"),
        ("-1.005", "-1.01"),
        ("999999999999999999.99", "999999999999999999.99"),
        ("0", "0.00"),
    ],
)
def test_money_serialization_uses_decimal_half_up(value, expected):
    assert decimal_string(Decimal(value)) == expected


@pytest.mark.parametrize(
    "key,schema",
    [
        ("stock", StockResponse),
        ("candle", CandleResponse),
        ("assets", AssetResponse),
        ("portfolio", PortfolioResponse),
        ("watchlist", WatchlistResponse),
    ],
)
def test_read_responses_match_published_mobile_fixtures(key, schema):
    path = Path(__file__).resolve().parents[3] / "docs/contracts/examples.json"
    example = json.loads(path.read_text(encoding="utf-8"))[key]
    assert schema.model_validate(example).model_dump(mode="json") == example
