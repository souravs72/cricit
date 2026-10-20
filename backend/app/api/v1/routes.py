"""Mobile API (/v1). Public feed endpoints are CDN-cacheable; everything else needs a user."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import UserClaims, public
from app.core.config import Settings, get_settings
from app.core.db import get_session
from app.core.errors import AppError
from app.schemas.auth import FirebaseExchangeIn, RefreshIn, TokenPair
from app.schemas.feed import FeedPage, Lang, Tab
from app.services import feed as feed_service

router = APIRouter(prefix="/v1")


class NotBuiltYet(AppError):
    status_code = 501
    code = "not_implemented"


@router.get("/feed", response_model=FeedPage, dependencies=[Depends(public)])
async def get_feed(
    response: Response,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    tab: Tab = "feed",
    lang: Lang = "en",
    cursor: Annotated[str | None, Query(max_length=200)] = None,
) -> FeedPage:
    response.headers["Cache-Control"] = "public, s-maxage=60, stale-while-revalidate=300"
    return await feed_service.get_feed(session, settings, tab=tab, lang=lang, cursor=cursor)


@router.get("/config", dependencies=[Depends(public)])
async def get_config(response: Response) -> dict[str, object]:
    response.headers["Cache-Control"] = "public, s-maxage=600"
    return {
        "min_app_version": "1.0.0",
        "tabs": ["feed", "video", "domestic", "international", "nxtspot"],
        "ad_every_n_cards": 6,
        "nxtspot_every_n_cards": 8,
    }


@router.post("/auth/firebase", response_model=TokenPair, dependencies=[Depends(public)])
async def exchange_firebase_token(body: FirebaseExchangeIn) -> TokenPair:
    raise NotBuiltYet("T05: verify Firebase ID token, upsert user, open session, issue tokens")


@router.post("/auth/refresh", response_model=TokenPair, dependencies=[Depends(public)])
async def refresh(body: RefreshIn) -> TokenPair:
    raise NotBuiltYet("T05: rotate refresh token; on reuse revoke the whole family")


@router.post("/auth/logout", status_code=204)
async def logout(claims: UserClaims) -> None:
    raise NotBuiltYet("T05: revoke session claims.sid")


@router.get("/me")
async def get_me(claims: UserClaims) -> dict[str, str]:
    return {"id": claims.sub}


@router.delete("/me", status_code=204)
async def delete_me(claims: UserClaims) -> None:
    raise NotBuiltYet("T31: soft-delete user, revoke all sessions, purge after 30 days")
