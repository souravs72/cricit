"""Production-grade Ingestion & Intelligence Engine Benchmark.

Empirically benchmarks:
1. In-memory content extraction (trafilatura throughput & memory overhead).
2. Two-pass deduplication engine (rapidfuzz title similarity + numbers guardrails).
3. AI Intelligence pipeline (deterministic card generation, Hindi Devanagari translation).
4. Concurrency scaling & memory footprint across varying batch loads.

Usage:
    uv run python scripts/benchmark_ingest.py
"""

from __future__ import annotations

import asyncio
import os
import resource
import sys
import time
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from app.ai.client import SUMMARY_SCHEMA, LocalDeterministicLLMClient
from app.ai.validators import looks_hindi, validate_summary
from app.ingestion.dedupe import (
    Candidate,
    check_pass1,
)
from app.services.ai_pipeline import extract_in_memory_text


def get_memory_mb() -> float:
    """Return max RSS memory usage in Megabytes."""
    rusage = resource.getrusage(resource.RUSAGE_SELF)
    # Linux reports ru_maxrss in kilobytes
    return rusage.ru_maxrss / 1024.0


SAMPLE_HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head><title>{title}</title></head>
<body>
<nav><a href="/">Home</a><a href="/news">News</a></nav>
<article>
    <h1>{title}</h1>
    <p class="byline">By Cricit News Desk | Published: November 2026</p>
    <div class="content">
        <p>In an exhilarating day of Test cricket at the Optus Stadium in Perth, the contest swung violently between bat and ball. {body}</p>
        <p>The visiting team established an imposing total of {score1} after a defiant middle-order partnership. In response, the hosts could only muster {score2} before the final session concluded under fading light.</p>
        <p>Spectators witnessed masterclass seam bowling, relentless lines, and acrobatic fielding that set the tone for the remainder of the series.</p>
    </div>
</article>
<footer><p>&copy; 2026 Cricit Media Inc.</p></footer>
</body>
</html>"""


@dataclass
class BenchmarkResult:
    name: str
    operations_count: int
    duration_seconds: float
    ops_per_second: float
    avg_latency_ms: float
    p95_latency_ms: float
    memory_start_mb: float
    memory_end_mb: float
    memory_delta_mb: float


def benchmark_extraction(count: int = 100) -> BenchmarkResult:
    """Benchmark in-memory HTML extraction using trafilatura."""
    start_mem = get_memory_mb()
    samples = [
        SAMPLE_HTML_TEMPLATE.format(
            title=f"Perth Test Match Report - Session {i % 5 + 1}",
            body=f"Jasprit Bumrah bowled an inspired spell taking {i % 6 + 1} wickets while maintaining a disciplined economy rate.",
            score1=f"{200 + i * 2}/6",
            score2=f"{150 + i}/10",
        )
        for i in range(count)
    ]

    latencies: list[float] = []
    t0 = time.perf_counter()
    for html in samples:
        s0 = time.perf_counter()
        extracted = extract_in_memory_text(html)
        latencies.append((time.perf_counter() - s0) * 1000.0)
        assert extracted and len(extracted) > 50

    total_time = time.perf_counter() - t0
    end_mem = get_memory_mb()

    latencies.sort()
    p95 = latencies[int(len(latencies) * 0.95)]
    return BenchmarkResult(
        name="In-Memory HTML Text Extraction (trafilatura)",
        operations_count=count,
        duration_seconds=total_time,
        ops_per_second=count / total_time,
        avg_latency_ms=(total_time / count) * 1000.0,
        p95_latency_ms=p95,
        memory_start_mb=start_mem,
        memory_end_mb=end_mem,
        memory_delta_mb=end_mem - start_mem,
    )


def benchmark_deduplication(corpus_size: int = 500) -> BenchmarkResult:
    """Benchmark two-pass title fuzzy matching and score/number guardrails."""
    start_mem = get_memory_mb()

    # Pre-populate candidate pool
    now = datetime.now(UTC)
    candidates = [
        Candidate(
            title=f"Perth Test Day {i % 5 + 1}: India lead by {100 + i} runs against Australia",
            published_at=now,
            tags=frozenset({"india", "australia"}),
        )
        for i in range(corpus_size)
    ]

    queries = [
        # Exact match
        "Perth Test Day 1: India lead by 100 runs against Australia",
        # Near duplicate (minor rephrasing)
        "India lead Australia by 101 runs on Day 2 in Perth Test match",
        # Colliding title with different numbers (must NOT auto-merge)
        "Perth Test Day 1: India lead by 250 runs against Australia",
        # Distinct story
        "England name playing XI for Rawalpindi test against Pakistan",
        # High-similarity variants
        "Perth Test Day 3: India command 102 run lead over Australia at Optus",
    ] * 40  # 200 queries against 500 candidates = 100,000 candidate comparisons

    latencies: list[float] = []
    t0 = time.perf_counter()
    for q in queries:
        s0 = time.perf_counter()
        c = Candidate(title=q, published_at=now, tags=frozenset({"india"}))
        _ = check_pass1(c, candidates)
        latencies.append((time.perf_counter() - s0) * 1000.0)

    total_time = time.perf_counter() - t0
    end_mem = get_memory_mb()

    latencies.sort()
    p95 = latencies[int(len(latencies) * 0.95)]
    return BenchmarkResult(
        name="Two-Pass Deduplication Engine (RapidFuzz + Number Guardrails)",
        operations_count=len(queries),
        duration_seconds=total_time,
        ops_per_second=len(queries) / total_time,
        avg_latency_ms=(total_time / len(queries)) * 1000.0,
        p95_latency_ms=p95,
        memory_start_mb=start_mem,
        memory_end_mb=end_mem,
        memory_delta_mb=end_mem - start_mem,
    )


async def benchmark_intelligence_pipeline(count: int = 100) -> BenchmarkResult:
    """Benchmark deterministic AI summarization and Devanagari Hindi generation."""
    start_mem = get_memory_mb()
    client = LocalDeterministicLLMClient()

    articles = [
        (
            f"Jasprit Bumrah delivers 147 kph masterclass in Perth Test Match {i}",
            "Perth: Jasprit Bumrah produced an unplayable spell of reverse-swing bowling on Day 2 at Optus Stadium. "
            "The Indian pace spearhead removed the Australian top order with balls clocking above 145 kph. "
            "His toe-crushing yorker to dismiss the set batsman was celebrated as one of the deliveries of the year. "
            "Australia were dismissed for 180, handing India a decisive 120-run first-innings advantage heading into day three.",
        )
        for i in range(count)
    ]

    latencies: list[float] = []
    t0 = time.perf_counter()
    for title, body in articles:
        s0 = time.perf_counter()
        intel = await client.complete_json(
            system="Summarize cricket article",
            user=f"Article title: {title}\nArticle text: {body}",
            schema=SUMMARY_SCHEMA,
        )
        latencies.append((time.perf_counter() - s0) * 1000.0)

        # Validate factual guarantees
        v_res = validate_summary(
            summary=intel.data["summary"],
            headline=intel.data["headline"],
            source_text=f"{title}\n{body}",
        )
        assert v_res.ok
        assert looks_hindi(intel.data["summary_hi"])
        assert len(intel.data["summary"].split()) >= 30

    total_time = time.perf_counter() - t0
    end_mem = get_memory_mb()

    latencies.sort()
    p95 = latencies[int(len(latencies) * 0.95)]
    return BenchmarkResult(
        name="AI Intelligence Layer (Summaries + Hindi Translation)",
        operations_count=count,
        duration_seconds=total_time,
        ops_per_second=count / total_time,
        avg_latency_ms=(total_time / count) * 1000.0,
        p95_latency_ms=p95,
        memory_start_mb=start_mem,
        memory_end_mb=end_mem,
        memory_delta_mb=end_mem - start_mem,
    )


async def benchmark_concurrent_ingest_scaling() -> list[dict[str, Any]]:
    """Measure throughput across concurrency levels 1, 5, 10, 20."""
    client = LocalDeterministicLLMClient()
    concurrencies = [1, 5, 10, 20]
    results = []

    async def _mock_pipeline(idx: int) -> None:
        raw_html = SAMPLE_HTML_TEMPLATE.format(
            title=f"Match Report #{idx}",
            body="Clinical performance with bat and ball.",
            score1="240/5",
            score2="180/10",
        )
        text = extract_in_memory_text(raw_html)
        await client.complete_json(
            system="Summarize",
            user=f"Article title: Match Report #{idx}\nArticle text: {text}",
            schema=SUMMARY_SCHEMA,
        )

    for c in concurrencies:
        sem = asyncio.Semaphore(c)
        tasks_count = 50

        async def _bounded_work(i: int, s: asyncio.Semaphore = sem) -> None:
            async with s:
                await _mock_pipeline(i)

        t0 = time.perf_counter()
        await asyncio.gather(*[_bounded_work(i) for i in range(tasks_count)])
        dur = time.perf_counter() - t0
        ops = tasks_count / dur
        results.append({
            "concurrency": c,
            "tasks": tasks_count,
            "duration_s": dur,
            "throughput_articles_per_sec": ops,
            "latency_per_batch_ms": (dur / tasks_count) * 1000.0,
        })

    return results


async def main() -> None:
    print("=" * 80)
    print(" CRICIT NEWS INGESTION & INTELLIGENCE ENGINE: EMPIRICAL BENCHMARK SUITE")
    print("=" * 80)
    print(f"PID: {os.getpid()} | Initial RSS Memory: {get_memory_mb():.2f} MB\n")

    res_extract = benchmark_extraction(100)
    res_dedupe = benchmark_deduplication(500)
    res_intel = await benchmark_intelligence_pipeline(100)
    concurrent_results = await benchmark_concurrent_ingest_scaling()

    benchmarks = [res_extract, res_dedupe, res_intel]
    for b in benchmarks:
        print(f"▶ {b.name}")
        print(f"  • Processed:      {b.operations_count} items in {b.duration_seconds:.3f} s")
        print(f"  • Throughput:     {b.ops_per_second:.1f} ops/sec")
        print(f"  • Avg Latency:    {b.avg_latency_ms:.2f} ms")
        print(f"  • P95 Latency:    {b.p95_latency_ms:.2f} ms")
        print(f"  • Memory Start:   {b.memory_start_mb:.2f} MB | End: {b.memory_end_mb:.2f} MB (Delta: +{b.memory_delta_mb:.2f} MB)")
        print()

    print("▶ Concurrency Scaling Analysis (Articles Extracted, Deduplicated & Summarized)")
    print(f"  {'Concurrency':<12} {'Batch Items':<12} {'Duration (s)':<14} {'Throughput (art/s)':<20} {'Latency/Item (ms)':<18}")
    print("  " + "-" * 74)
    for cr in concurrent_results:
        print(
            f"  {cr['concurrency']:<12} "
            f"{cr['tasks']:<12} "
            f"{cr['duration_s']:<14.3f} "
            f"{cr['throughput_articles_per_sec']:<20.1f} "
            f"{cr['latency_per_batch_ms']:<18.2f}"
        )

    print("\n" + "=" * 80)
    print(f" Benchmark complete. Final RSS Memory: {get_memory_mb():.2f} MB")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(main())
