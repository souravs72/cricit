"""Deny by default: every route must declare an auth dependency from app.core.auth."""

from fastapi.dependencies.models import Dependant
from fastapi.routing import APIRoute

from app.core.auth import AUTH_MARKER
from app.main import create_app


def _has_auth(dep: Dependant) -> bool:
    if dep.call is not None and getattr(dep.call, AUTH_MARKER, False):
        return True
    return any(_has_auth(sub) for sub in dep.dependencies)


def test_every_route_declares_auth():
    app = create_app()
    missing = [
        f"{sorted(r.methods)} {r.path}"
        for r in app.routes
        if isinstance(r, APIRoute) and not _has_auth(r.dependant)
    ]
    assert not missing, f"Routes without an auth dependency: {missing}"


def test_user_route_needs_token(client):
    r = client.get("/v1/me")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "unauthorized"
    assert r.json()["error"]["request_id"]


def test_user_route_with_token(client, token_for):
    r = client.get("/v1/me", headers={"Authorization": f"Bearer {token_for()}"})
    assert r.status_code == 200 and r.json() == {"id": "u1"}


def test_admin_route_rejects_user_token(client, token_for):
    r = client.get("/admin/v1/me", headers={"Authorization": f"Bearer {token_for()}"})
    assert r.status_code == 401


def test_permission_enforced_by_role(client, token_for):
    viewer = client.get(
        "/admin/v1/sources", headers={"Authorization": f"Bearer {token_for('viewer')}"}
    )
    editor = client.get(
        "/admin/v1/sources", headers={"Authorization": f"Bearer {token_for('editor')}"}
    )
    assert viewer.status_code == 403
    assert editor.status_code == 501  # allowed through; endpoint lands in T09


def test_security_headers_and_request_id(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert r.headers["X-Request-ID"]
