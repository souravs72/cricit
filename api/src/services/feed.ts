/**
 * Feed building with a KV cache. Cache keys include a version number that publishing bumps
 * (`bumpFeedVersion`), so a publish shows up immediately without listing or deleting keys.
 * T16 adds ad and Nxtspot interleaving.
 */
import { drizzle } from "drizzle-orm/d1";

import type { Config } from "../core/config";
import { AppError } from "../core/errors";
import type { Post } from "../db/schema";
import * as postsRepo from "../repositories/posts";
import { decodeCursor, encodeCursor, type Card, type FeedPage, type Lang, type Tab } from "../schemas/feed";

const TAB_CATEGORY: Record<Tab, Post["category"] | null> = {
  feed: null,
  domestic: "domestic",
  international: "international",
  nxtspot: "grassroots",
};

const CACHE_TTL_S = 60;
const VERSION_KEY = "feed:version";

export function toCard(post: Post, lang: Lang, shareBase: string): Card {
  return {
    id: post.id,
    kind: post.kind,
    category: post.category,
    headline: lang === "hi" && post.headlineHi ? post.headlineHi : post.headline,
    summary: lang === "hi" && post.summaryHi ? post.summaryHi : post.summary,
    image: post.imageUrl,
    video_id: post.videoId,
    source: post.authorCredit ? { name: post.authorCredit } : null,
    url: post.originalUrl,
    tags: post.tags,
    published_at: new Date(post.publishedAt ?? 0).toISOString(),
    share_url: `${shareBase}/p/${post.id}`,
  };
}

export async function buildFeedPage(
  env: Env,
  cfg: Config,
  args: { tab: Tab; lang: Lang; cursor?: string | undefined },
): Promise<FeedPage> {
  const after = args.cursor ? decodeCursor(args.cursor) : null;
  const limit = cfg.FEED_PAGE_SIZE;
  const rows = await postsRepo.listPublished(drizzle(env.DB), {
    category: TAB_CATEGORY[args.tab],
    after,
    limit: limit + 1,
  });
  const page = rows.slice(0, limit);
  const last = page.at(-1);
  return {
    items: page.map((p) => toCard(p, args.lang, cfg.SHARE_BASE_URL)),
    next_cursor: rows.length > limit && last?.publishedAt != null ? encodeCursor(last.publishedAt, last.id) : null,
  };
}

/** Cached read path. A KV outage degrades to a direct D1 read, never an error. */
export async function getFeed(env: Env, cfg: Config, args: { tab: Tab; lang: Lang; cursor?: string | undefined }) {
  try {
    const version = (await env.CACHE.get(VERSION_KEY)) ?? "0";
    const key = `feed:${version}:${args.tab}:${args.lang}:${args.cursor ?? "first"}`;
    const cached = await env.CACHE.get<FeedPage>(key, "json");
    if (cached) return cached;
    const page = await buildFeedPage(env, cfg, args);
    await env.CACHE.put(key, JSON.stringify(page), { expirationTtl: CACHE_TTL_S });
    return page;
  } catch (e) {
    if (e instanceof AppError) throw e;
    return buildFeedPage(env, cfg, args);
  }
}

export async function bumpFeedVersion(env: Env): Promise<void> {
  await env.CACHE.put(VERSION_KEY, String(Date.now()));
}
