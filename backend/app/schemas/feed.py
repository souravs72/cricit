"""Card payload: one shape for every card kind so the app renders one widget per kind."""

import base64
import json
import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, HttpUrl

from app.core.errors import ValidationFailed

Tab = Literal["feed", "video", "domestic", "international", "nxtspot"]
Lang = Literal["en", "hi"]


class CardSource(BaseModel):
    name: str
    logo: HttpUrl | None = None


class Card(BaseModel):
    id: uuid.UUID
    kind: Literal["read", "video", "nxtspot"]
    category: str
    headline: str
    summary: str
    image: HttpUrl | None = None
    video_id: str | None = None
    source: CardSource | None = None
    url: HttpUrl | None = None
    tags: list[str] = Field(default_factory=list)
    published_at: datetime
    share_url: HttpUrl


class AdSlot(BaseModel):
    kind: Literal["ad"] = "ad"
    format: Literal["admob_native", "sponsored_card", "full_page", "footer"]
    campaign_id: uuid.UUID | None = None
    title: str | None = None
    body: str | None = None
    creative: HttpUrl | None = None
    click_url: HttpUrl | None = None


class FeedPage(BaseModel):
    items: list[Card | AdSlot]
    next_cursor: str | None = None


def encode_cursor(published_at: datetime, post_id: uuid.UUID) -> str:
    raw = json.dumps({"t": published_at.isoformat(), "id": str(post_id)}).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        data = json.loads(base64.urlsafe_b64decode(padded))
        return datetime.fromisoformat(data["t"]), uuid.UUID(data["id"])
    except (ValueError, KeyError, TypeError) as exc:
        raise ValidationFailed("Invalid cursor", field="cursor") from exc
