"""Mobile API (/v1). Public feed endpoints are CDN-cacheable; everything else needs a user."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import UserClaims, public
from app.core.config import Settings, get_settings
from app.core.db import get_session
from app.core.errors import NotBuiltYet
from app.core.ratelimit import RateLimiter
from app.core.redis import get_redis
from app.schemas.auth import FirebaseExchangeIn, RefreshIn, TokenPair
from app.schemas.events import EventsIn
from app.schemas.feed import FeedPage, Lang, Tab
from app.schemas.newsroom import DiscoverOut
from app.services import events as events_service
from app.services import feed as feed_service
from app.services import newsroom as newsroom_service
from app.services import tokens as token_service
from app.services import user_auth as user_auth_service
from app.services.feed import FEED_CACHE_CONTROL

router = APIRouter(prefix="/v1")


@router.get("/feed", response_model=FeedPage, dependencies=[Depends(public)])
async def get_feed(
    response: Response,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    tab: Tab = "feed",
    lang: Lang = "en",
    cursor: Annotated[str | None, Query(max_length=200)] = None,
) -> FeedPage:
    response.headers["Cache-Control"] = FEED_CACHE_CONTROL
    return await feed_service.get_feed(
        session,
        settings,
        tab=tab,
        lang=lang,
        cursor=cursor,
        redis=get_redis(),
    )


@router.get("/config", dependencies=[Depends(public)])
async def get_config(
    response: Response,
    settings: Annotated[Settings, Depends(get_settings)],
) -> dict[str, object]:
    response.headers["Cache-Control"] = "public, s-maxage=600"
    return {
        "min_app_version": "1.0.0",
        "tabs": ["feed", "video", "domestic", "international", "nxtspot"],
        "ad_every_n_cards": settings.ad_every_n_cards,
        "nxtspot_every_n_cards": settings.nxtspot_every_n_cards,
    }


@router.post("/events", status_code=204, dependencies=[Depends(public)])
async def post_events(request: Request, body: EventsIn) -> None:
    redis = get_redis()
    ip = request.client.host if request.client else "unknown"
    limiter = RateLimiter(redis)
    await limiter.hit(f"events-ip:{ip}", limit=120, window_s=60)
    await limiter.hit(f"events:{body.device_id}", limit=60, window_s=60)
    await events_service.record(redis, body.events)


@router.get("/search", response_model=FeedPage, dependencies=[Depends(public)])
async def search(
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    q: Annotated[str, Query(min_length=1, max_length=80)],
    lang: Lang = "en",
) -> FeedPage:
    """Public: readers search published cards. Rate-limited per IP."""
    ip = request.client.host if request.client else "unknown"
    await RateLimiter(get_redis()).hit(f"search:{ip}", limit=30, window_s=60)
    return await newsroom_service.search(session, settings, q=q, lang=lang)


@router.get("/discover", response_model=DiscoverOut, dependencies=[Depends(public)])
async def discover(
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    lang: Lang = "en",
) -> DiscoverOut:
    return await newsroom_service.discover(session, settings, lang=lang)


@router.post("/auth/firebase", response_model=TokenPair, dependencies=[Depends(public)])
async def exchange_firebase_token(
    body: FirebaseExchangeIn,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenPair:
    return await user_auth_service.exchange_id_token(
        session, settings, id_token=body.id_token, device_id=body.device_id
    )


@router.post("/auth/refresh", response_model=TokenPair, dependencies=[Depends(public)])
async def refresh(
    body: RefreshIn,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenPair:
    pair = await token_service.rotate_refresh(session, settings, body.refresh_token)
    await session.commit()
    return pair


@router.post("/auth/logout", status_code=204)
async def logout(
    claims: UserClaims,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> None:
    await token_service.logout(session, claims.sid)
    await session.commit()


@router.get("/me")
async def get_me(claims: UserClaims) -> dict[str, str]:
    return {"id": claims.sub}


@router.delete("/me", status_code=204)
async def delete_me(claims: UserClaims) -> None:
    raise NotBuiltYet("T31: soft-delete user, revoke all sessions, purge after 30 days")
