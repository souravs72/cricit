---
name: content-intelligence-engine
description: Decoupled AI intelligence processing standard for article content extraction, summarization, entity classification, bilingual generation (English/Hindi), factual validation, and cost auditing.
compatibility: Python 3.12+, Pydantic v2, Trafilatura, LLM APIs (Gemini, OpenAI, Anthropic, Local)
metadata:
  author: principal-systems-architect
  version: "1.0.0"
  standard: "agentskills.io"
---

# Content Intelligence Engine Standard

## 1. Architectural Guardrails
- **Asynchronous & Decoupled**: Article ingestion and AI intelligence must never run synchronously on the critical path of raw ingestion. Raw articles are persisted first; AI processing runs asynchronously.
- **In-Memory Body Extraction**: The raw full article text is extracted in memory using `trafilatura` or clean HTML selectors for prompt generation, but is NEVER stored permanently in PostgreSQL (preserving storage efficiency and intellectual property boundaries).
- **Cost & Token Auditing**: Every LLM transaction is audited in the `ai_jobs` table, tracking:
  - `model` (e.g. `gemini-2.5-flash`, `gpt-4o-mini`, `local-deterministic`)
  - `prompt_version` (e.g. `summarize_v1`)
  - `input_tokens` and `output_tokens`
  - `cost_inr` (calculated based on provider pricing)
  - `status` (`ok`, `invalid`, `error`)

## 2. Validation & Hallucination Prevention
Before any AI summary can auto-publish without editorial review:
1. **Length Bounds**: 45 to 75 words (ideal target: ~60 words).
2. **Headline Limit**: Maximum 80 characters, factual hook, no clickbait.
3. **Number Hallucination Check**: Every numerical value in the generated headline or summary MUST exist in the source text.
4. **Devanagari Verification**: Hindi fields (`headline_hi`, `summary_hi`) must contain valid Devanagari script (`looks_hindi() >= 0.5`).
5. **Relevance Threshold**: `relevance >= 0.5` is required for auto-publishing; sports stories with `relevance < 0.5` route to the `review` queue.
