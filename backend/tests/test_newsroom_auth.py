"""Auth and validation for newsroom + search. These hit no database.

Callers: pytest (`make check-backend`). APIs: GET /v1/search, GET /admin/v1/{sources,posts,
review,ads,audit,nxtspot,stats/overview}. Schemas: SearchQuery, AppError JSON.
"""

from pydantic import ValidationError

from app.core.config import Settings
from app.core.errors import NotBuiltYet
from app.schemas.newsroom import SearchQuery
from app.services.user_auth import exchange_id_token


def test_search_requires_query(client):
    r = client.get("/v1/search")
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "validation_failed"


def test_search_rejects_overlong_query(client):
    r = client.get("/v1/search", params={"q": "x" * 81})
    assert r.status_code == 422


def test_search_query_schema():
    assert SearchQuery(q="Gill").q == "Gill"
    try:
        SearchQuery(q="")
        raise AssertionError("empty query must fail")
    except ValidationError:
        pass


def test_unauthenticated_admin_lists_are_401(client):
    """pytest. API: GET lists + POST /admin/v1/sources and publish. User: build it."""
    for path in (
        "/admin/v1/sources",
        "/admin/v1/posts",
        "/admin/v1/review",
        "/admin/v1/ads",
        "/admin/v1/audit",
        "/admin/v1/nxtspot",
        "/admin/v1/stats/overview",
    ):
        assert client.get(path).status_code == 401, path
    assert (
        client.post(
            "/admin/v1/sources",
            json={
                "name": "X",
                "type": "news",
                "adapter": "rss",
                "adapter_config": {
                    "feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"
                },
            },
        ).status_code
        == 401
    )
    assert (
        client.post("/admin/v1/posts/00000000-0000-0000-0000-000000000001/publish").status_code
        == 401
    )


def test_viewer_cannot_write_surfaces(client, token_for):
    headers = {"Authorization": f"Bearer {token_for('viewer')}"}
    assert client.get("/admin/v1/review", headers=headers).status_code == 403
    assert client.get("/admin/v1/ads", headers=headers).status_code == 403
    assert client.get("/admin/v1/audit", headers=headers).status_code == 403
    assert client.get("/admin/v1/nxtspot", headers=headers).status_code == 403
    assert client.get("/admin/v1/sources", headers=headers).status_code == 403
    assert (
        client.post(
            "/admin/v1/sources",
            headers=headers,
            json={
                "name": "No",
                "type": "news",
                "adapter": "rss",
                "adapter_config": {
                    "feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"
                },
            },
        ).status_code
        == 403
    )
    assert (
        client.post(
            "/admin/v1/posts/00000000-0000-0000-0000-000000000001/publish",
            headers=headers,
        ).status_code
        == 403
    )


def test_ssrf_on_create_is_422_without_touching_the_database(client, token_for):
    headers = {"Authorization": f"Bearer {token_for('editor')}"}
    r = client.post(
        "/admin/v1/sources",
        headers=headers,
        json={
            "name": "SSRF",
            "type": "news",
            "adapter": "rss",
            "adapter_config": {"feed_url": "http://127.0.0.1/rss.xml"},
        },
    )
    assert r.status_code == 422


def test_editor_is_kept_off_ads_and_audit(token_for):
    from fastapi.testclient import TestClient

    from app.main import create_app

    quiet = TestClient(create_app(), raise_server_exceptions=False)
    headers = {"Authorization": f"Bearer {token_for('editor')}"}
    assert quiet.get("/admin/v1/ads", headers=headers).status_code == 403
    assert quiet.get("/admin/v1/audit", headers=headers).status_code == 403
    review = quiet.get("/admin/v1/review", headers=headers)
    assert review.status_code != 401
    assert review.status_code != 403


async def test_firebase_blocked_outside_local() -> None:
    settings = Settings.model_construct(env="production")
    try:
        await exchange_id_token(None, settings, id_token="x", device_id="d1")  # type: ignore[arg-type]
        raise AssertionError("staging/production must not mint tokens")
    except NotBuiltYet as exc:
        assert "T05" in str(exc)
