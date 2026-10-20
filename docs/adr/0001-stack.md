# ADR 0001: Stack and shape

**Status:** accepted · **Date:** 2026-10-20

## Decision

FastAPI + PostgreSQL + Redis/ARQ backend, Next.js 16 + shadcn/ui admin, Flutter app, one VPS behind
Cloudflare. Feeds are pre-built and cached so reads scale without code changes.

## Why not Frappe

Frappe's admin is free, but its runtime is heavy (≈2 GB idle), its REST layer is slow for a
high-read public feed, and the client asked for fast, lightweight and easy to scale.

## Why Next.js over Refine for the admin

The client wants a classy, production-grade product. A themed shadcn/ui panel gives full control of
the design system for ~3–4 extra days.

## Consequences

- One backend language (Python) for API, ingestion and AI.
- Auth, RBAC and audit are our code, so they are tested in CI (see `tests/test_route_auth.py`).
- Dedupe uses a three-way verdict; uncertain matches always go to an editor (measured in T12 notes).
