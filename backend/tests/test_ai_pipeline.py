from __future__ import annotations

from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.client import LocalDeterministicLLMClient
from app.ai.validators import looks_hindi, validate_summary
from app.models import Post
from app.services.ai_pipeline import extract_in_memory_text, process_post_intelligence


def test_extract_in_memory_text():
    html = """
    <html>
      <head><title>Test Title</title></head>
      <body>
        <nav><a href="/">Home</a></nav>
        <article>
          <h1>Bumrah strikes with three wickets at Perth</h1>
          <p>Jasprit Bumrah produced a devastating spell of fast bowling on day two at Perth.
          He took 3 wickets for 14 runs in a five-over burst to leave Australia struggling at 67 for 4.
          The pace and bounce tested the Australian top order from the very first over.</p>
        </article>
        <footer>Copyright 2026</footer>
      </body>
    </html>
    """
    extracted = extract_in_memory_text(html)
    assert "Bumrah strikes" in extracted or "fast bowling" in extracted
    assert len(extracted.split()) > 20


def test_validate_summary_numbers():
    source = "Shubman Gill scored 104 runs off 150 balls with 12 boundaries at Perth."
    ok_sum = "Shubman Gill anchored the innings with a brilliant 104 in Perth, guiding India to a commanding position."
    bad_sum = "Shubman Gill scored 104 runs and 7 sixes to lead the team to victory."  # '7' not in source

    v_ok = validate_summary(summary=ok_sum, headline="Gill hits 104", source_text=source, min_words=10)
    assert v_ok.ok is True

    v_bad = validate_summary(summary=bad_sum, headline="Gill hits 104", source_text=source, min_words=10)
    assert v_bad.ok is False
    assert any("numbers not in source" in r for r in v_bad.reasons)


def test_looks_hindi():
    assert looks_hindi("शुभमन गिल ने पर्थ में शानदार शतक बनाया") is True
    assert looks_hindi("Shubman Gill Perth Century") is False


@pytest.mark.asyncio
async def test_deterministic_llm_completion():
    client = LocalDeterministicLLMClient()
    user_prompt = """
    Article title: Virat Kohli masterclass nets session in Perth
    Source: Cricbuzz
    Article text:
    Virat Kohli spent two intense hours in the nets refining his front-foot stride against left-arm pace ahead of the opening Test at Perth.
    He faced over 120 deliveries and looked sharp and focused.
    """
    res = await client.complete_json(system="You are an editor", user=user_prompt, schema={})
    assert res.data["headline"] != ""
    assert len(res.data["headline"]) <= 80
    assert len(res.data["summary"].split()) >= 45
    assert res.data["category"] in ("domestic", "international", "grassroots")
    assert len(res.data["tags"]) > 0
    assert looks_hindi(res.data["summary_hi"]) is True
    assert res.data["relevance"] >= 0.5


@pytest.mark.asyncio
async def test_process_post_intelligence_mock_db():
    mock_db = MagicMock(spec=AsyncSession)
    mock_db.commit = AsyncMock()
    mock_db.add = MagicMock()

    post = Post(
        id=uuid4(),
        kind="read",
        status="review",
        category="international",
        headline="Gill 104 keeps India in front at Perth",
        summary="Shubman Gill hit a fifth Test century at Perth to put India ahead.",
        original_url="https://cricinfo.com/gill-104",
        url_hash="test-hash-ai-1",
        author_credit="ESPNcricinfo",
        published_at=datetime.now(UTC),
    )

    raw_article = (
        "Shubman Gill’s fifth Test hundred dragged India to 287 for 5 after a two-hour rain break. "
        "He added 112 with Pant, then saw off Starc with the new ball. Australia need seven wickets on a pitch "
        "that is starting to stay low. The Perth pitch offered steep bounce in the morning session."
    )

    ai_job = await process_post_intelligence(
        mock_db,
        post,
        source_name="ESPNcricinfo",
        raw_content=raw_article,
        client=LocalDeterministicLLMClient(),
    )

    assert ai_job.status in ("ok", "invalid")
    assert post.prompt_version == "summarize_v1"
    assert post.summary_hi is not None
    assert looks_hindi(post.summary_hi) is True
    assert len(post.tags) > 0
    mock_db.commit.assert_awaited_once()
