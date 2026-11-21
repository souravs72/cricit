---
name: news-ingestion-pipeline
description: Production-grade concurrent news ingestion pipeline standard. Covers async multi-protocol fetching (RSS, Atom, Sitemap, HTML, YouTube, X), SSRF protection, host rate limiting, ETag caching, two-pass deduplication, and circuit breaking.
compatibility: Python 3.12+, FastAPI, SQLAlchemy AsyncIO, Redis, ARQ
metadata:
  author: principal-systems-architect
  version: "1.0.0"
  standard: "agentskills.io"
---

# News Ingestion Pipeline Standard

## 1. Principles & Ingestion Architecture
- **Fault Isolation**: Every ingestion job runs in an isolated execution boundary. Network timeouts, SSL handshake failures, DNS resolution errors, or malformed XML/JSON must NEVER crash or delay sibling source jobs.
- **Circuit Breaker**: Maintain a consecutive failure counter (`source.consecutive_failures`). On 5 consecutive failures, transition the source to inactive (`is_active = False`) and record `last_error` for editorial triage.
- **Polite Crawling & SSRF Protection**:
  - All outbound URLs pass through `assert_safe_to_fetch()` to prevent Server-Side Request Forgery (SSRF) against loopback (`127.0.0.1`), RFC 1918 private subnets, link-local addresses, and cloud metadata endpoints (`169.254.169.254`).
  - Cache `robots.txt` per host for 24 hours.
  - Enforce a strict 1 request per second concurrency lock per target host (`polite.py`).
- **Conditional HTTP (ETag & Last-Modified)**:
  - Cache the HTTP `ETag` and `Last-Modified` headers on the `Source` model.
  - Send `If-None-Match` and `If-Modified-Since` headers on subsequent polls.
  - When the server returns `304 Not Modified`, terminate processing immediately with zero database writes and zero LLM calls.

## 2. Ingestion Stages & Data Flow
```text
[Cron / Trigger] 
       │
       ▼
[Fetch Due Sources] ── (Idempotent slot key: fetch:{source_id}:{time_slot})
       │
       ▼
[Adapter Fetch] (RSS / Atom / Sitemap / HTML / YouTube / X)
       │
  (304 / Error) ──► Record Success/Failure & Exit
       │
  (200 OK + Raw Items)
       │
       ▼
[Pass 1: Canonicalization & URL Hash Dedupe]
       │
  (Known URL Hash) ──► Skip (Zero Cost)
       │
  (New URL)
       │
       ▼
[Pass 2: Title Similarity Dedupe (RapidFuzz)]
       ├── Similarity >= 95% (DUPLICATE) ──► Add to post_sources
       ├── Similarity 85-94% (POSSIBLE)   ──► Mark for Editor Review
       └── Similarity < 85%  (DISTINCT)   ──► Ingest & Queue for Intelligence
```
