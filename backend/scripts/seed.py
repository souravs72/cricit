"""Idempotent local data so the newsroom and app have examples of every entity (T03).

Run: `make seed` (API/Postgres up). Prints the owner password once to stdout
and writes `.seed-credentials` (gitignored) so re-runs keep the same login.
"""

from __future__ import annotations

import asyncio
import hashlib
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.db import get_sessionmaker
from app.core.security import hash_password, hash_refresh_token
from app.models import (
    AdCampaign,
    Admin,
    AdminRecoveryCode,
    AiJob,
    AuditLog,
    NxtspotSubmission,
    Post,
    Source,
    User,
)

ROOT = Path(__file__).resolve().parents[2]
CREDS = ROOT / ".seed-credentials"
DEMO_TOTP = "JBSWY3DPEHPK3PXP"
DEMO_RECOVERY = "a1b2c3-d4e5f6"
NOW = datetime.now(UTC)

SOURCES = [
    ("ESPNcricinfo", "news", "rss", "international", "auto"),
    ("BBC Sport Cricket", "news", "rss", "international", "review"),
    ("Times of India Cricket", "news", "rss", "domestic", "review"),
    ("BCCI", "news", "html", "domestic", "auto"),
    ("ICC", "news", "html", "international", "review"),
    ("Nxtspot", "news", None, "grassroots", "review"),
    ("BCCI YouTube", "youtube_channel", "youtube", "international", "auto"),
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
    "BCCI": {"kind": "html", "listing_url": "https://www.bcci.tv/news"},
    "ICC": {"kind": "html", "listing_url": "https://www.icc-cricket.com/news"},
    "BCCI YouTube": {"kind": "youtube", "channel_id": "UCiErvZ3iVs0LnWoJBWcuK8Q"},
}

CARDS: list[tuple[str, str, str, str, str, str, str, list[str]]] = [
    (
        "read",
        "international",
        "Gill 104 keeps India in front at Perth",
        "Shubman Gill's fifth Test hundred dragged India to 287 for 5 after a rain break.",
        "गिल की 104 से पर्थ में भारत आगे",
        "शुभमन गिल के पाँचवें टेस्ट शतक ने बारिश के बाद भारत को 287/5 तक पहुँचाया।",
        "ESPNcricinfo",
        ["India", "breaking"],
    ),
    (
        "video",
        "international",
        "Bumrah's yorker that bent the stumps",
        "A 147 kph yorker, late reverse, off stump cartwheeling. Official upload only.",
        "बुमराह की यॉर्कर जिसने स्टंप मोड़ दिए",
        "147 किमी/घंटा की यॉर्कर, देर से रिवर्स, ऑफ स्टंप उखड़ा।",
        "BCCI",
        ["India"],
    ),
    (
        "read",
        "domestic",
        "Mumbai take the lead after Jaiswal's 178",
        "Yashasvi Jaiswal batted through day two of the Ranji semi-final. Mumbai declared on 412 for 6.",
        "जयसवाल के 178 के बाद मुंबई आगे",
        "रणजी सेमीफ़ाइनल में जयसवाल ने पूरे दूसरे दिन खेला।",
        "Times of India Cricket",
        ["India"],
    ),
    (
        "nxtspot",
        "grassroots",
        "A 16-year-old takes 7 for 9 in Palakkad",
        "Anjali Menon took 7 for 9 in an under-19 game on a damp matting wicket.",
        "पालक्काड़ में 16 साल के खिलाड़ी ने लिए 7 विकेट",
        "अंजलि मेनन ने अंडर-19 मैच में 7 विकेट लिए।",
        "Nxtspot",
        ["Nxtspot"],
    ),
    (
        "read",
        "international",
        "England rest Archer for the Oval ODI",
        "Jofra Archer will skip Thursday's match after scans showed tightness in his right side.",
        "इंग्लैंड ने ओवल वनडे से आर्चर को आराम दिया",
        "जोफ्रा आर्चर गुरुवार का मैच छोड़ेंगे।",
        "BBC Sport Cricket",
        ["England"],
    ),
    (
        "read",
        "domestic",
        "WPL: Knight Riders hold their nerve in a super over",
        "Kolkata Knight Riders Women tied with Delhi, then won the super over by two runs.",
        "डब्ल्यूपीएल: सुपर ओवर में नाइट राइडर्स जीतीं",
        "बारिश वाले मैच में टाई के बाद कोलकाता ने सुपर ओवर दो रन से जीता।",
        "ESPNcricinfo",
        ["India"],
    ),
]


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
        elif not (existing.adapter_config or {}).get("feed_url") and not (
            existing.adapter_config or {}
        ).get("listing_url"):
            existing.adapter_config = cfg
    await session.flush()

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

    templates = list(CARDS)
    for i in range(60):
        kind, category, headline, summary, hi_h, hi_s, src_name, tags = templates[
            i % len(templates)
        ]
        suffix = "" if i < len(templates) else f" ({i})"
        url = f"https://cricit.app/seed/{i}"
        if await session.scalar(select(Post).where(Post.url_hash == _hash_url(url))):
            continue
        src = await _source(session, src_name)
        session.add(
            Post(
                kind=kind,
                status="published",
                category=category,
                headline=(headline + suffix)[:160],
                summary=summary,
                headline_hi=hi_h,
                summary_hi=hi_s,
                original_url=url,
                url_hash=_hash_url(url),
                source_id=src.id,
                video_id="dQw4w9wgGcQ" if kind == "video" else None,
                author_credit=src_name,
                tags=tags,
                prompt_version="summarize_v1",
                published_at=NOW - timedelta(minutes=18 + i * 7),
            )
        )

    for i, headline in enumerate(
        (
            "Draft: Rohit rests the new ball for Vizag",
            "Draft: Delhi pitch report before the pink-ball Test",
            "Draft: Under-19 spinner from Ranchi on Nxtspot",
        )
    ):
        url = f"https://cricit.app/seed/review/{i}"
        if await session.scalar(select(Post).where(Post.url_hash == _hash_url(url))):
            continue
        src = await _source(session, "ESPNcricinfo" if i < 2 else "Nxtspot")
        session.add(
            Post(
                kind="nxtspot" if i == 2 else "read",
                status="review",
                category="domestic" if i != 2 else "grassroots",
                headline=headline,
                summary="Waiting on an editor. Numbers checked; photo still in review.",
                original_url=url,
                url_hash=_hash_url(url),
                source_id=src.id,
                author_credit=src.name,
                tags=["India"],
                prompt_version="summarize_v1",
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
                is_active=True,
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

    if await session.scalar(select(AiJob).where(AiJob.prompt_version == "summarize_v1")) is None:
        session.add(
            AiJob(
                model="claude-sonnet",
                prompt_version="summarize_v1",
                input_tokens=420,
                output_tokens=90,
                cost_inr=0.12,
                status="ok",
            )
        )

    if await session.scalar(select(AuditLog).where(AuditLog.action == "seed.ok")) is None:
        session.add(
            AuditLog(
                admin_id=admin.id,
                action="seed.ok",
                entity="system",
                diff={"posts": 60, "sources": len(SOURCES)},
                ts=NOW,
                note="Showcase seed",
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
