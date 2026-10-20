/** Integration tests against D1 (with migrations) and KV, inside the Workers runtime. */
import { env } from "cloudflare:workers";
import { drizzle } from "drizzle-orm/d1";
import { beforeEach, describe, expect, it } from "vitest";

import { uuidv7 } from "../src/core/ids";
import { insertMany } from "../src/db/batch";
import { posts, type NewPost } from "../src/db/schema";
import { buildFeedPage, bumpFeedVersion } from "../src/services/feed";
import { call, cfg } from "./helpers";

const T0 = Date.UTC(2026, 9, 20, 12);

function post(i: number, minutes: number, extra: Partial<NewPost> = {}): NewPost {
  return {
    id: uuidv7(T0 + minutes * 60_000),
    kind: "read",
    status: "published",
    category: "international",
    headline: `Story ${i}`,
    summary: "Summary",
    originalUrl: `https://example.com/${i}`,
    urlHash: `hash-${i}`,
    publishedAt: T0 + minutes * 60_000,
    ...extra,
  };
}

const db = () => drizzle(env.DB);

beforeEach(async () => {
  await db().delete(posts);
  await bumpFeedVersion(env);
});

describe("feed pagination", () => {
  it("never repeats or skips a card when new posts arrive mid-scroll", async () => {
    const config = { ...cfg(), FEED_PAGE_SIZE: 5 };
    await insertMany(
      db(),
      posts,
      Array.from({ length: 12 }, (_, i) => post(i, i)),
    );

    const page1 = await buildFeedPage(env, config, { tab: "feed", lang: "en", cursor: undefined });
    await insertMany(db(), posts, [post(100, 60), post(101, 61), post(102, 62)]);
    const page2 = await buildFeedPage(env, config, { tab: "feed", lang: "en", cursor: page1.next_cursor ?? undefined });
    const page3 = await buildFeedPage(env, config, { tab: "feed", lang: "en", cursor: page2.next_cursor ?? undefined });

    const seen = [page1, page2, page3].flatMap((p) => p.items.map((c) => ("headline" in c ? c.headline : "")));
    expect(seen).toEqual(Array.from({ length: 12 }, (_, i) => `Story ${11 - i}`));
    expect(page3.next_cursor).toBeNull();
  });

  it("filters by tab and serves Hindi with English fallback", async () => {
    await insertMany(db(), posts, [
      post(1, 1, { category: "domestic", headlineHi: "कहानी 1" }),
      post(2, 2, { category: "international" }),
      post(3, 3, { category: "domestic" }),
    ]);
    const page = await buildFeedPage(env, cfg(), { tab: "domestic", lang: "hi", cursor: undefined });
    expect(page.items.map((c) => ("headline" in c ? c.headline : ""))).toEqual(["Story 3", "कहानी 1"]);
  });

  it("hides drafts and review items", async () => {
    await insertMany(db(), posts, [post(1, 1), post(2, 2, { status: "review" }), post(3, 3, { status: "draft" })]);
    const page = await buildFeedPage(env, cfg(), { tab: "feed", lang: "en", cursor: undefined });
    expect(page.items).toHaveLength(1);
  });
});

describe("feed endpoint", () => {
  it("serves the cached page and shows new posts after a publish bumps the version", async () => {
    await insertMany(db(), posts, [post(1, 1)]);
    const first = await call("/v1/feed");
    expect(first.status).toBe(200);
    expect(first.headers.get("Cache-Control")).toContain("s-maxage=60");
    expect(((await first.json()) as { items: unknown[] }).items).toHaveLength(1);

    await insertMany(db(), posts, [post(2, 2)]);
    const stale = (await (await call("/v1/feed")).json()) as { items: unknown[] };
    expect(stale.items).toHaveLength(1); // still cached

    await bumpFeedVersion(env);
    const fresh = (await (await call("/v1/feed")).json()) as { items: unknown[] };
    expect(fresh.items).toHaveLength(2);
  });

  it("rejects a bad cursor with 422 and never lets the edge cache the error", async () => {
    const res = await call("/v1/feed?cursor=garbage");
    expect(res.status).toBe(422);
    expect(res.headers.get("Cache-Control")).toBe("no-store");
  });
});

describe("search", () => {
  it("finds published posts by prefix in English and Hindi, ignoring drafts", async () => {
    await insertMany(db(), posts, [
      post(1, 1, { headline: "Bumrah ruled out of Perth Test", headlineHi: "बुमराह पर्थ टेस्ट से बाहर" }),
      post(2, 2, { headline: "Gill hits century in Perth" }),
      post(3, 3, { headline: "Bumrah draft story", status: "draft" }),
    ]);
    const en = (await (await call("/v1/search?q=bumr")).json()) as { items: { headline: string }[] };
    expect(en.items.map((i) => i.headline)).toEqual(["Bumrah ruled out of Perth Test"]);
    const hi = (await (await call(`/v1/search?q=${encodeURIComponent("बुमराह")}&lang=hi`)).json()) as {
      items: { headline: string }[];
    };
    expect(hi.items).toHaveLength(1);
    const injection = await call(`/v1/search?q=${encodeURIComponent('perth" OR *')}`);
    expect(injection.status).toBe(200);
  });
});
