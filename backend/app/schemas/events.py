"""Batch of reader events from the app (T26).

Callers: POST /v1/events, services.events, tests/test_events.py.
Schema: EventsIn (device_id + up to 100 EventIn rows).
User: "audit the changes and implement more features and build the changes"
"""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

EventName = Literal["view", "open", "share", "bookmark", "ad_impression", "ad_click"]


class EventIn(BaseModel):
    name: EventName
    post_id: UUID | None = None
    campaign_id: UUID | None = None
    occurred_at: datetime | None = None


class EventsIn(BaseModel):
    device_id: str = Field(min_length=8, max_length=100, pattern=r"^[A-Za-z0-9._:-]+$")
    events: list[EventIn] = Field(max_length=100)
