"""Idempotent local data so the newsroom and app have examples of every entity (T03).

Run: `make seed` (API/Postgres up). Prints the owner password once to stdout
and writes `.seed-credentials` (gitignored) so re-runs keep the same login.
"""

from __future__ import annotations

import asyncio
import hashlib
import os
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from showcase_data import IMAGES, PUBLISHED, REVIEW

from app.core.db import get_sessionmaker
from app.core.security import hash_password, hash_refresh_token
from app.models import (
    AdCampaign,
    Admin,
    AdminRecoveryCode,
    AdStatsDaily,
    AiJob,
    AuditLog,
    NxtspotSubmission,
    Post,
    PostStatsDaily,
    Source,
    User,
)

ROOT = Path(__file__).resolve().parents[2]
CREDS = Path(os.environ.get("SEED_CREDS", str(ROOT / ".seed-credentials")))
DEMO_TOTP = "JBSWY3DPEHPK3PXP"
DEMO_RECOVERY = "a1b2c3-d4e5f6"
NOW = datetime.now(UTC)

SOURCES = [
    ("ESPNcricinfo", "news", "rss", "international", "auto"),
    ("BBC Sport Cricket", "news", "rss", "international", "review"),
    ("Times of India Cricket", "news", "rss", "domestic", "review"),
    ("BCCI", "news", "html", "domestic", "auto"),
    ("ICC", "news", "html", "international", "review"),
    ("IPL", "news", "html", "domestic", "review"),
    ("NDTV Sports", "news", "rss", "domestic", "review"),
    ("ESPNcricinfo (India)", "news", "rss", "international", "auto"),
    ("Nxtspot", "news", None, "grassroots", "review"),
    ("BCCI YouTube", "youtube_channel", "youtube", "international", "auto"),
    ("ICC YouTube", "youtube_channel", "youtube", "international", "auto"),
]

# Public feeds from docs/sources.md. Re-runs fill adapter_config if it was empty.
FEED_CONFIG: dict[str, dict[str, str]] = {
    "ESPNcricinfo": {
        "kind": "rss",
        "feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/0.xml",
    },
    "BBC Sport Cricket": {
        "kind": "rss",
        "feed_url": "https://feeds.bbci.co.uk/sport/cricket/rss.xml",
    },
    "Times of India Cricket": {
        "kind": "rss",
        "feed_url": "https://timesofindia.indiatimes.com/rssfeeds/4716741.cms",
    },
    "BCCI": {
        "kind": "html",
        "listing_url": "https://www.bcci.tv/news",
        "item_selector": "article a[href], a[href*='/news/']",
    },
    "ICC": {
        "kind": "html",
        "listing_url": "https://www.icc-cricket.com/news",
        "item_selector": "article a[href], a[href*='/news/']",
    },
    "IPL": {
        "kind": "html",
        "listing_url": "https://www.iplt20.com/news",
        "item_selector": "article a[href], a[href*='/news/']",
    },
    "BCCI YouTube": {"kind": "youtube", "channel_id": "UCiErvZ3iVs0LnWoJBWcuK8Q"},
    "ICC YouTube": {"kind": "youtube", "channel_id": "UCt2JXOLNxszYDuYHnmuLuJw"},
    "NDTV Sports": {
        "kind": "rss",
        "feed_url": "https://feeds.feedburner.com/ndtvsports-cricket",
    },
    "ESPNcricinfo (India)": {
        "kind": "rss",
        "feed_url": "https://www.espncricinfo.com/rss/content/story/feeds/6.xml",
    },
}

SOURCE_HEALTH: dict[str, dict[str, object]] = {
    "ESPNcricinfo": {"last_fetched_at": NOW - timedelta(minutes=4), "consecutive_failures": 0},
    "ESPNcricinfo (India)": {
        "last_fetched_at": NOW - timedelta(minutes=9),
        "consecutive_failures": 0,
    },
    "BBC Sport Cricket": {
        "last_fetched_at": NOW - timedelta(minutes=11),
        "consecutive_failures": 0,
    },
    "Times of India Cricket": {
        "last_fetched_at": NOW - timedelta(minutes=41),
        "consecutive_failures": 2,
        "last_error": "fetch failed",
    },
    "BCCI": {"last_fetched_at": NOW - timedelta(minutes=16), "consecutive_failures": 0},
    "ICC": {
        "last_fetched_at": NOW - timedelta(hours=6),
        "consecutive_failures": 3,
        "last_error": "paused — listing returned no items",
        "is_active": False,
    },
    "IPL": {"last_fetched_at": NOW - timedelta(minutes=22), "consecutive_failures": 0},
    "NDTV Sports": {"consecutive_failures": 0},
    "BCCI YouTube": {"last_fetched_at": NOW - timedelta(minutes=38), "consecutive_failures": 0},
    "ICC YouTube": {"last_fetched_at": NOW - timedelta(hours=2), "consecutive_failures": 0},
}


def _story_url(slug: str) -> str:
    return f"https://www.espncricinfo.com/cricket-news/{slug}"


def _password() -> str:
    if CREDS.exists():
        for line in CREDS.read_text(encoding="utf-8").splitlines():
            if line.startswith("password="):
                return line.split("=", 1)[1].strip()
    pwd = "cricit-owner-ok"
    CREDS.write_text(
        "email=owner@cricit.app\n"
        f"password={pwd}\n"
        f"totp_secret={DEMO_TOTP}\n"
        f"recovery={DEMO_RECOVERY}\n",
        encoding="utf-8",
    )
    return pwd


def _hash_url(url: str) -> str:
    return hashlib.sha256(url.encode()).hexdigest()


async def _source(session: AsyncSession, name: str) -> Source:
    row = await session.scalar(select(Source).where(Source.name == name))
    assert row is not None
    return row


async def seed(session: AsyncSession) -> None:
    password = _password()
    admin = await session.scalar(
        select(Admin).where(Admin.email.in_(("owner@cricit.app", "owner@cricit.local")))
    )
    if admin is None:
        admin = Admin(
            email="owner@cricit.app",
            name="Owner",
            password_hash=hash_password(password),
            role="owner",
            totp_secret=DEMO_TOTP,
            is_active=True,
        )
        session.add(admin)
        await session.flush()
        session.add(
            AdminRecoveryCode(admin_id=admin.id, code_hash=hash_refresh_token(DEMO_RECOVERY))
        )
    elif admin.email != "owner@cricit.app":
        admin.email = "owner@cricit.app"
    unused = await session.scalar(
        select(AdminRecoveryCode).where(
            AdminRecoveryCode.admin_id == admin.id,
            AdminRecoveryCode.used_at.is_(None),
        )
    )
    if unused is None:
        session.add(
            AdminRecoveryCode(admin_id=admin.id, code_hash=hash_refresh_token(DEMO_RECOVERY))
        )

    for name, typ, adapter, category, trust in SOURCES:
        existing = await session.scalar(select(Source).where(Source.name == name))
        cfg = FEED_CONFIG.get(name, {"kind": "none"})
        if existing is None:
            session.add(
                Source(
                    name=name,
                    type=typ,
                    adapter=adapter,
                    adapter_config=cfg,
                    default_category=category,
                    trust_level=trust,
                    is_active=True,
                    verified_at=NOW,
                )
            )
        else:
            current = dict(existing.adapter_config or {})
            for key, value in cfg.items():
                if not current.get(key):
                    current[key] = value
            existing.adapter_config = current
    await session.flush()
    for name, health in SOURCE_HEALTH.items():
        row = await session.scalar(select(Source).where(Source.name == name))
        if row is None:
            continue
        for key, value in health.items():
            setattr(row, key, value)

    if await session.scalar(select(User).where(User.phone == "9876543210")) is None:
        session.add(
            User(
                phone="9876543210",
                firebase_uid="dev:showcase-reader",
                name="Demo reader",
                language="en",
            )
        )
    await session.flush()
    demo_user = await session.scalar(select(User).where(User.phone == "9876543210"))

    by_slug: dict[str, Post] = {}
    for i, row in enumerate(PUBLISHED):
        kind, category, headline, summary, hi_h, hi_s, src_name, tags, slug, img = row
        url = _story_url(slug)
        existing_post = await session.scalar(select(Post).where(Post.url_hash == _hash_url(url)))
        if existing_post is not None:
            by_slug[slug] = existing_post
            continue
        src = await _source(session, src_name)
        post = Post(
            kind=kind,
            status="published",
            category=category,
            headline=headline[:160],
            summary=summary,
            headline_hi=hi_h,
            summary_hi=hi_s,
            image_url=IMAGES[img],
            original_url=url,
            url_hash=_hash_url(url),
            source_id=src.id,
            author_credit=src_name,
            tags=tags,
            prompt_version="summarize_v1",
            published_at=NOW - timedelta(minutes=12 + i * 11),
        )
        session.add(post)
        by_slug[slug] = post
    await session.flush()

    for headline, summary, src_name, category, kind, slug, dup_slug in REVIEW:
        url = _story_url(f"review/{slug}")
        if await session.scalar(select(Post).where(Post.url_hash == _hash_url(url))):
            continue
        src = await _source(session, src_name)
        dup = by_slug.get(dup_slug) if dup_slug else None
        session.add(
            Post(
                kind=kind,
                status="review",
                category=category,
                headline=headline[:160],
                summary=summary,
                original_url=url,
                url_hash=_hash_url(url),
                source_id=src.id,
                possible_duplicate_of=dup.id if dup is not None else None,
                author_credit=src.name,
                tags=["India"] if category != "grassroots" else ["Nxtspot"],
                prompt_version="summarize_v1",
                image_url=IMAGES[1],
            )
        )

    if not await session.scalar(select(AdCampaign).where(AdCampaign.advertiser == "Kineto Sports")):
        session.add(
            AdCampaign(
                advertiser="Kineto Sports",
                format="sponsored_card",
                creative_url="https://cdn.cricit.app/ads/kineto.png",
                click_url="https://example.com/kineto",
                title="Grip that lasts a whole Test",
                body="A sponsored card example. Falls in every sixth slot on My feed.",
                start_at=NOW - timedelta(days=1),
                end_at=NOW + timedelta(days=30),
                frequency=6,
                daily_cap=10000,
                is_active=True,
            )
        )
    if not await session.scalar(select(AdCampaign).where(AdCampaign.advertiser == "Railways XI")):
        session.add(
            AdCampaign(
                advertiser="Railways XI",
                format="footer",
                creative_url="https://cdn.cricit.app/ads/railways.png",
                click_url="https://example.com/railways",
                title="Club trials this Sunday",
                start_at=NOW - timedelta(days=2),
                end_at=NOW + timedelta(days=14),
                frequency=8,
                daily_cap=4000,
                is_active=True,
            )
        )
    if not await session.scalar(
        select(AdCampaign).where(AdCampaign.advertiser == "Pitchside Cover")
    ):
        session.add(
            AdCampaign(
                advertiser="Pitchside Cover",
                format="sponsored_card",
                creative_url="https://cdn.cricit.app/ads/pitchside.png",
                click_url="https://example.com/pitchside",
                title="Insure the season, not just the match",
                body="Direct-sold card. Sits in every sixth slot on My feed.",
                start_at=NOW - timedelta(days=3),
                end_at=NOW + timedelta(days=45),
                frequency=6,
                daily_cap=8000,
                is_active=True,
            )
        )
    if not await session.scalar(select(AdCampaign).where(AdCampaign.advertiser == "ClubKit Co")):
        session.add(
            AdCampaign(
                advertiser="ClubKit Co",
                format="footer",
                creative_url="https://cdn.cricit.app/ads/clubkit.png",
                click_url="https://example.com/clubkit",
                title="Match whites that survive red soil",
                start_at=NOW - timedelta(days=5),
                end_at=NOW + timedelta(days=21),
                frequency=8,
                daily_cap=2500,
                is_active=True,
            )
        )
    if not await session.scalar(select(AdCampaign).where(AdCampaign.advertiser == "Monsoon Nets")):
        session.add(
            AdCampaign(
                advertiser="Monsoon Nets",
                format="full_page",
                creative_url="https://cdn.cricit.app/ads/monsoon.png",
                click_url="https://example.com/monsoon",
                title="Indoor nets — June campaign (ended)",
                start_at=NOW - timedelta(days=90),
                end_at=NOW - timedelta(days=20),
                frequency=10,
                daily_cap=1000,
                is_active=False,
            )
        )

    if (
        await session.scalar(
            select(NxtspotSubmission).where(NxtspotSubmission.submitter_name == "Anjali Menon")
        )
        is None
    ):
        session.add(
            NxtspotSubmission(
                user_id=demo_user.id if demo_user else None,
                submitter_name="Anjali Menon",
                location="Palakkad, Kerala",
                raw_text="Took 7 for 9 in the under-19 district game on a damp matting wicket.",
                status="drafted",
            )
        )
    if (
        await session.scalar(
            select(NxtspotSubmission).where(NxtspotSubmission.submitter_name == "Rahul Kulkarni")
        )
        is None
    ):
        session.add(
            NxtspotSubmission(
                submitter_name="Rahul Kulkarni",
                location="Pune, Maharashtra",
                raw_text="Club spinner, 19, 6 for 11 in the Poona club league. Video on the way.",
                status="new",
            )
        )
    for name, location, text, status in (
        (
            "Meera Sharma",
            "Jorhat, Assam",
            "164 off 88 in a 30-over school game. Fourteen sixes. Scorebook photo attached.",
            "published",
        ),
        (
            "Linthoi Devi",
            "Imphal, Manipur",
            "3 for 19 as Manipur women beat Nagaland by 41. First state T20 win.",
            "new",
        ),
        (
            "S. Kumar",
            "Unknown",
            "Buy followers cheap. WhatsApp this number.",
            "rejected",
        ),
    ):
        if (
            await session.scalar(
                select(NxtspotSubmission).where(NxtspotSubmission.submitter_name == name)
            )
            is None
        ):
            session.add(
                NxtspotSubmission(
                    submitter_name=name,
                    location=location,
                    raw_text=text,
                    status=status,
                )
            )

    job_count = int(await session.scalar(select(func.count()).select_from(AiJob)) or 0)
    if job_count < 6:
        for tokens_in, tokens_out, cost, status in (
            (420, 90, 0.12, "ok"),
            (510, 88, 0.14, "ok"),
            (380, 70, 0.09, "ok"),
            (640, 110, 0.18, "ok"),
            (290, 40, 0.06, "invalid"),
            (800, 130, 0.22, "ok"),
        ):
            session.add(
                AiJob(
                    model="claude-sonnet",
                    prompt_version="summarize_v1",
                    input_tokens=tokens_in,
                    output_tokens=tokens_out,
                    cost_inr=cost,
                    status=status,
                )
            )

    await session.flush()
    today = NOW.date()
    published_rows = list(
        (await session.scalars(select(Post).where(Post.status == "published"))).all()
    )
    for i, post in enumerate(published_rows):
        exists = await session.get(PostStatsDaily, {"post_id": post.id, "day": today})
        if exists is not None:
            continue
        session.add(
            PostStatsDaily(
                post_id=post.id,
                day=today,
                views=420 + i * 37,
                opens=80 + i * 9,
                shares=4 + (i % 7),
                bookmarks=2 + (i % 5),
            )
        )
    for campaign in (await session.scalars(select(AdCampaign))).all():
        exists = await session.get(AdStatsDaily, {"campaign_id": campaign.id, "day": today})
        if exists is not None:
            continue
        session.add(
            AdStatsDaily(
                campaign_id=campaign.id,
                day=today,
                impressions=12000 if campaign.is_active else 0,
                clicks=180 if campaign.is_active else 0,
            )
        )

    for action, entity, note in (
        ("seed.ok", "system", "Showcase seed"),
        ("admin.login", "admin", "Owner signed in from the newsroom"),
        ("posts.publish", "post", "Published Gill 104 keeps India in front at Perth"),
        ("posts.reject", "post", "Rejected a spam Nxtspot tip"),
        ("sources.pause", "source", "Paused ICC after empty listing"),
        ("ads.create", "ad", "Pitchside Cover sponsored card"),
    ):
        if await session.scalar(
            select(AuditLog).where(AuditLog.action == action, AuditLog.note == note)
        ):
            continue
        session.add(
            AuditLog(
                admin_id=admin.id,
                action=action,
                entity=entity,
                diff={},
                ts=NOW - timedelta(minutes=15),
                note=note,
            )
        )
    await session.commit()
    print("Seeded CRICIT showcase data.")
    print("  newsroom: owner@cricit.app")
    print(f"  password: {password}")
    print(
        f"  TOTP secret: {DEMO_TOTP}  "
        f"(python -c \"import pyotp; print(pyotp.TOTP('{DEMO_TOTP}').now())\")"
    )
    print(f"  recovery: {DEMO_RECOVERY}")
    print(f"  wrote {CREDS}")


async def main() -> None:
    maker = get_sessionmaker()
    async with maker() as session:
        await seed(session)


if __name__ == "__main__":
    asyncio.run(main())
