"""Source adapter contract. One adapter per source type: rss, sitemap, html."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Protocol


@dataclass(frozen=True)
class RawItem:
    url: str
    title: str
    published_at: datetime | None
    image_url: str | None = None
    extra: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class FetchResult:
    items: list[RawItem]
    etag: str | None = None
    last_modified: str | None = None
    not_modified: bool = False


class SourceAdapter(Protocol):
    async def fetch(
        self, config: dict[str, Any], *, etag: str | None, last_modified: str | None
    ) -> FetchResult: ...
