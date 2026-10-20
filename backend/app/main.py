"""App factory: middleware, error handlers, routers, health checks."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.admin.routes import router as admin_router
from app.api.v1.routes import router as v1_router
from app.core.auth import public
from app.core.config import get_settings
from app.core.db import get_engine
from app.core.errors import install_error_handlers
from app.core.logging import RequestIdMiddleware, SecurityHeadersMiddleware, configure_logging
from app.core.redis import get_redis


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    yield
    await get_engine().dispose()
    await get_redis().aclose()


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    if settings.sentry_dsn:
        sentry_sdk.init(dsn=settings.sentry_dsn, environment=settings.env, traces_sample_rate=0.1)

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.env in {"local", "test"} else None,
        redoc_url=None,
    )
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[settings.admin_origin],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
    )
    app.add_middleware(RequestIdMiddleware)
    install_error_handlers(app)

    @app.get("/health", dependencies=[Depends(public)], include_in_schema=False)
    async def health() -> dict[str, str]:
        """Liveness: the process is up."""
        return {"status": "ok"}

    @app.get("/ready", dependencies=[Depends(public)], include_in_schema=False)
    async def ready() -> dict[str, str]:
        """Readiness: database and Redis answer."""
        async with get_engine().connect() as conn:
            await conn.execute(text("SELECT 1"))
        await get_redis().ping()
        return {"status": "ready"}

    app.include_router(v1_router)
    app.include_router(admin_router)
    return app


app = create_app()
