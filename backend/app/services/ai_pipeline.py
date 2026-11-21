"""Decoupled AI Intelligence Processing Pipeline.

Extracts article body in-memory (using trafilatura), runs schema-guided LLM
completion, verifies constraints with validate_summary, audits costs in ai_jobs,
and enriches the Post model without storing the full article text in DB.
"""

from __future__ import annotations

from typing import Any

import structlog
import trafilatura
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.client import SUMMARY_SCHEMA, LLMClient, get_llm_client, load_prompt
from app.ai.validators import validate_summary
from app.models import Post
from app.models.ads import AiJob
from app.repositories import settings as settings_repo

log = structlog.get_logger()


def extract_in_memory_text(html_or_text: str | None, *, min_words: int = 30) -> str:
    """Extract clean article body text in memory. Never persisted to database."""
    if not html_or_text:
        return ""
    # Attempt trafilatura article extraction
    extracted = trafilatura.extract(
        html_or_text,
        include_comments=False,
        include_tables=False,
        no_fallback=False,
    )
    if extracted and len(extracted.split()) >= min_words:
        return extracted
    # Fallback to plain text stripped of HTML tags
    import re
    from html import unescape

    clean = re.sub(r"<[^>]+>", " ", html_or_text)
    clean = re.sub(r"\s+", " ", unescape(clean)).strip()
    return clean


async def process_post_intelligence(
    db: AsyncSession,
    post: Post,
    *,
    source_name: str | None = None,
    raw_content: str | None = None,
    client: LLMClient | None = None,
) -> AiJob:
    """Run AI summarization, categorization, bilingual translation, and validation."""
    if client is not None:
        llm = client
    else:
        app_cfg = await settings_repo.get_settings(db)
        llm = get_llm_client(app_cfg) if (app_cfg and app_cfg.llm_api_key) else get_llm_client()
    version, template = load_prompt("summarize_v1")

    # Extract article text in memory
    article_text = extract_in_memory_text(raw_content or post.summary or post.headline)
    if not article_text:
        article_text = f"{post.headline}. {post.summary}"

    user_prompt = template.format(
        title=post.headline,
        source_name=source_name or post.author_credit or "News Source",
        article_text=article_text[:4000],  # Bounded prompt size
    )

    error_msg: str | None = None
    status = "ok"
    result_data: dict[str, Any] = {}

    try:
        llm_res = await llm.complete_json(
            system="You are a professional cricket journalist and news editor for CRICIT.",
            user=user_prompt,
            schema=SUMMARY_SCHEMA,
            max_tokens=600,
        )
        result_data = llm_res.data
        model_name = llm_res.model
        in_tokens = llm_res.input_tokens
        out_tokens = llm_res.output_tokens
        cost_inr = llm_res.cost_inr

        # Validate summary
        val = validate_summary(
            summary=result_data.get("summary", ""),
            headline=result_data.get("headline", ""),
            source_text=f"{post.headline} {article_text}",
        )
        if not val.ok:
            status = "invalid"
            error_msg = f"Validation failed: {', '.join(val.reasons)}"
            log.warning("ai_validation_failed", post_id=str(post.id), reasons=val.reasons)

    except Exception as exc:
        status = "error"
        error_msg = str(exc)[:500]
        model_name = getattr(llm, "model", "unknown")
        in_tokens = 0
        out_tokens = 0
        cost_inr = 0.0
        log.error("ai_intelligence_error", post_id=str(post.id), error=error_msg)

    # Record AI Job audit row
    ai_job = AiJob(
        post_id=post.id,
        model=model_name,
        prompt_version=version,
        input_tokens=in_tokens,
        output_tokens=out_tokens,
        cost_inr=cost_inr,
        status=status,
        error=error_msg,
    )
    db.add(ai_job)

    # Enrich the Post if AI succeeded
    if status in ("ok", "invalid") and result_data:
        headline = result_data.get("headline")
        if headline and isinstance(headline, str):
            post.headline = headline[:160]

        summary = result_data.get("summary")
        if summary and isinstance(summary, str):
            post.summary = summary

        category = result_data.get("category")
        if category in ("domestic", "international", "grassroots"):
            post.category = category

        tags = result_data.get("tags")
        if isinstance(tags, list):
            post.tags = [str(t)[:60] for t in tags[:8]]

        headline_hi = result_data.get("headline_hi")
        if headline_hi and isinstance(headline_hi, str):
            post.headline_hi = headline_hi[:200]

        summary_hi = result_data.get("summary_hi")
        if summary_hi and isinstance(summary_hi, str):
            post.summary_hi = summary_hi

        post.prompt_version = version

        # Routing decision:
        relevance = float(result_data.get("relevance", 0.5))
        if status == "invalid" or relevance < 0.5:
            post.status = "review"

    await db.commit()
    return ai_job
