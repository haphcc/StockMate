"""LB CP2: watchlist isolation and retry/concurrent idempotency."""

from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.stock import Stock
from app.models.watchlist import Watchlist

pytestmark = pytest.mark.integration


def test_watchlist_add_delete_repeated_and_isolated(cp_client, cp_user, add_stock):
    headers = cp_user[2]
    add_stock()
    assert cp_client.get("/api/watchlist", headers=headers).json() == []
    first = cp_client.post("/api/watchlist", json={"stock_symbol": " fpt "}, headers=headers)
    second = cp_client.post("/api/watchlist", json={"stock_symbol": "FPT"}, headers=headers)
    assert first.status_code == second.status_code == 201
    assert first.json() == second.json()
    assert first.json()["stock"]["stock_symbol"] == "FPT"
    assert first.json()["stock"]["current_price"] == "100000.00"
    other = cp_client.post(
        "/api/auth/register",
        json={
            "full_name": "Other",
            "email": "other@example.com",
            "phone_number": "0907654321",
            "password": "Matkhau@123",
        },
    ).json()
    other_headers = {"Authorization": "Bearer " + other["access_token"]}
    assert cp_client.get("/api/watchlist", headers=other_headers).json() == []
    assert cp_client.delete("/api/watchlist/FPT", headers=other_headers).status_code == 204
    assert len(cp_client.get("/api/watchlist", headers=headers).json()) == 1
    for _ in range(2):
        response = cp_client.delete("/api/watchlist/fpt", headers=headers)
        assert response.status_code == 204 and response.content == b""
    assert cp_client.get("/api/watchlist", headers=headers).json() == []
    assert cp_client.delete("/api/watchlist/NOPE", headers=headers).status_code == 204


def test_watchlist_auth_invalid_and_missing_stock(cp_client, cp_user):
    assert cp_client.get("/api/watchlist").status_code == 401
    assert cp_client.post("/api/watchlist", json={"stock_symbol": "FPT"}).status_code == 401
    assert cp_client.delete("/api/watchlist/FPT").status_code == 401
    for data in [{}, {"stock_symbol": " "}, {"stock_symbol": "A%"}]:
        response = cp_client.post("/api/watchlist", json=data, headers=cp_user[2])
        assert response.status_code == 422
    assert (
        cp_client.post(
            "/api/watchlist", json={"stock_symbol": "NOPE"}, headers=cp_user[2]
        ).status_code
        == 404
    )


def test_legacy_lists_merge_without_duplicate_and_use_current_quote(
    cp_client,
    cp_user,
    add_stock,
    pg_engine,
):
    customer_id, _, headers = cp_user
    stock_id = add_stock()
    other_stock = add_stock("AAA")
    with Session(pg_engine) as db:
        db.add_all(
            [
                Watchlist(customer_id=customer_id, stock_id=stock_id, list_name="Legacy A"),
                Watchlist(customer_id=customer_id, stock_id=stock_id, list_name="Legacy B"),
                Watchlist(customer_id=customer_id, stock_id=other_stock, list_name="Legacy A"),
            ]
        )
        db.commit()
    rows = cp_client.get("/api/watchlist", headers=headers).json()
    assert len(rows) == 2
    assert [row["watchlist_id"] for row in rows] == sorted(row["watchlist_id"] for row in rows)
    repeated = cp_client.post("/api/watchlist", json={"stock_symbol": "FPT"}, headers=headers)
    assert repeated.json()["watchlist_id"] == rows[0]["watchlist_id"]
    with Session(pg_engine) as db:
        db.get(Stock, stock_id).current_price = "101000.00"
        db.commit()
    assert (
        cp_client.get("/api/watchlist", headers=headers).json()[0]["stock"]["current_price"]
        == "101000.00"
    )
    cp_client.delete("/api/watchlist/FPT", headers=headers)
    with Session(pg_engine) as db:
        assert (
            db.scalar(
                select(func.count())
                .select_from(Watchlist)
                .where(
                    Watchlist.customer_id == customer_id,
                    Watchlist.stock_id == stock_id,
                )
            )
            == 0
        )


def test_concurrent_watchlist_add_is_idempotent(cp_client, cp_user, add_stock, pg_engine):
    add_stock()

    def add(_):
        return cp_client.post("/api/watchlist", json={"stock_symbol": "FPT"}, headers=cp_user[2])

    with ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(add, range(6)))
    assert all(result.status_code == 201 for result in results)
    assert len({result.json()["watchlist_id"] for result in results}) == 1
    with Session(pg_engine) as db:
        assert db.scalar(select(func.count()).select_from(Watchlist)) == 1
