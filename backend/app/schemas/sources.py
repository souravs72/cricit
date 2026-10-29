"""Create/update payloads for sources. adapter_config is typed per adapter (T09).

Callers: admin routes POST/PATCH /admin/v1/sources, services.sources, tests/test_sources_schema.py.
API: POST/PATCH /admin/v1/sources, POST /admin/v1/sources/{id}/test.
Schemas: SourceCreate, SourcePatch, RssAdapterConfig (feed_url), TestFetchOut.
User: "Check what is tobe built now into this - build it"
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal, Self

from pydantic import BaseModel, Field, model_validator

from app.core.errors import ValidationFailed
from app.ingestion.ssrf import assert_public_http_url

Category = Literal["domestic", "international", "grassroots"]
Trust = Literal["auto", "review"]
Adapter = Literal["rss", "sitemap", "html", "youtube"]
SourceType = Literal["news", "youtube_channel", "youtube_search", "x"]


class RssAdapterConfig(BaseModel):
    kind: Literal["rss"] = "rss"
    feed_url: str
    etag: str | None = None
    last_modified: str | None = None

    @model_validator(mode="after")
    def _public_feed(self) -> Self:
        self.feed_url = assert_public_http_url(self.feed_url, field="feed_url")
        return self


class SitemapAdapterConfig(BaseModel):
    kind: Literal["sitemap"] = "sitemap"
    sitemap_url: str
    etag: str | None = None
    last_modified: str | None = None

    @model_validator(mode="after")
    def _public_map(self) -> Self:
        self.sitemap_url = assert_public_http_url(self.sitemap_url, field="sitemap_url")
        return self


class HtmlAdapterConfig(BaseModel):
    kind: Literal["html"] = "html"
    listing_url: str
    item_selector: str = Field(default="article a[href], a[href*='/news/']", max_length=240)
    title_selector: str | None = Field(default=None, max_length=240)
    etag: str | None = None
    last_modified: str | None = None

    @model_validator(mode="after")
    def _public_listing(self) -> Self:
        self.listing_url = assert_public_http_url(self.listing_url, field="listing_url")
        return self


class YoutubeAdapterConfig(BaseModel):
    kind: Literal["youtube"] = "youtube"
    channel_id: str = Field(min_length=8, max_length=40)


class EmptyAdapterConfig(BaseModel):
    kind: Literal["none"] = "none"


def normalised_config(adapter: str | None, raw: dict[str, Any] | None) -> dict[str, Any]:
    kind = adapter or "none"
    data = {**(raw or {}), "kind": kind}
    mapping: dict[str, type[BaseModel]] = {
        "rss": RssAdapterConfig,
        "sitemap": SitemapAdapterConfig,
        "html": HtmlAdapterConfig,
        "youtube": YoutubeAdapterConfig,
        "none": EmptyAdapterConfig,
    }
    model = mapping.get(kind)
    if model is None:
        raise ValueError("Unknown adapter")
    try:
        return model.model_validate(data).model_dump()
    except ValidationFailed as exc:
        raise ValueError(exc.message) from exc


class SourceCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    type: SourceType
    adapter: Adapter | None = None
    adapter_config: dict[str, Any] = Field(default_factory=dict)
    default_category: Category = "international"
    trust_level: Trust = "review"
    fetch_interval_min: int = Field(default=10, ge=2, le=1440)
    is_active: bool = True
    priority: int = Field(default=5, ge=0, le=10)

    @model_validator(mode="after")
    def _typed_config(self) -> Self:
        self.adapter_config = normalised_config(self.adapter, self.adapter_config)
        return self


class SourcePatch(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    adapter: Adapter | None = None
    adapter_config: dict[str, Any] | None = None
    default_category: Category | None = None
    trust_level: Trust | None = None
    fetch_interval_min: int | None = Field(default=None, ge=2, le=1440)
    is_active: bool | None = None
    priority: int | None = Field(default=None, ge=0, le=10)

    @model_validator(mode="after")
    def _typed_config(self) -> Self:
        if self.adapter is None and self.adapter_config is None:
            return self
        if self.adapter is None:
            raise ValueError("adapter is required when adapter_config is set")
        self.adapter_config = normalised_config(self.adapter, self.adapter_config)
        return self


class TestFetchItem(BaseModel):
    url: str
    title: str
    published_at: datetime | None = None


class TestFetchOut(BaseModel):
    not_modified: bool = False
    item_count: int
    items: list[TestFetchItem]
