"""Feed building. Ticket T16 adds the Redis cache, ad/Nxtspot interleaving and Hindi text."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.models import Post
from app.repositories import posts as posts_repo
from app.schemas.feed import Card, CardSource, FeedPage, Lang, Tab, decode_cursor, encode_cursor

_TAB_CATEGORY: dict[Tab, str | None] = {
    "feed": None,
    "domestic": "domestic",
    "international": "international",
    "nxtspot": "grassroots",
}


def to_card(post: Post, lang: Lang, share_base: str) -> Card:
    headline = post.headline_hi if lang == "hi" and post.headline_hi else post.headline
    summary = post.summary_hi if lang == "hi" and post.summary_hi else post.summary
    assert post.published_at is not None
    return Card(
        id=post.id,
        kind=post.kind,
        category=post.category,
        headline=headline,
        summary=summary,
        image=post.image_url,
        video_id=post.video_id,
        source=CardSource(name=post.author_credit) if post.author_credit else None,
        url=post.original_url,
        tags=post.tags,
        published_at=post.published_at,
        share_url=f"{share_base}/p/{post.id}",
    )


async def get_feed(
    session: AsyncSession,
    settings: Settings,
    *,
    tab: Tab,
    lang: Lang,
    cursor: str | None,
) -> FeedPage:
    after = decode_cursor(cursor) if cursor else None
    limit = settings.feed_page_size
    rows = await posts_repo.list_published(
        session, category=_TAB_CATEGORY[tab], kind=None, after=after, limit=limit + 1
    )
    has_more = len(rows) > limit
    rows = rows[:limit]
    share_base = settings.cdn_base_url or "https://cricit.app"
    items = [to_card(p, lang, share_base) for p in rows]
    next_cursor = None
    if has_more and rows and rows[-1].published_at:
        next_cursor = encode_cursor(rows[-1].published_at, rows[-1].id)
    return FeedPage(items=list(items), next_cursor=next_cursor)
