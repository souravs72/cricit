/** Mobile API (/v1). Public feed endpoints are CDN-cacheable; everything else needs a user. */
import { zValidator } from "@hono/zod-validator";
import { drizzle } from "drizzle-orm/d1";
import { Hono } from "hono";
import { z } from "zod";

import { claimsOf, currentUser, publicRoute, type AppEnv } from "../core/auth";
import { getConfig } from "../core/config";
import { NotBuiltYet } from "../core/errors";
import { rateLimit, validationHook } from "../core/http";
import * as postsRepo from "../repositories/posts";
import { FeedQuery, SearchQuery } from "../schemas/feed";
import { getFeed, toCard } from "../services/feed";

const FirebaseExchange = z.object({ id_token: z.string().min(20), device_id: z.string().min(8).max(100) });
const Refresh = z.object({ refresh_token: z.string().min(20) });

export const v1 = new Hono<AppEnv>()
  .get("/feed", publicRoute, rateLimit("RL_PUBLIC"), zValidator("query", FeedQuery, validationHook), async (c) => {
    const q = c.req.valid("query");
    c.header("Cache-Control", "public, max-age=30, s-maxage=60, stale-while-revalidate=300");
    return c.json(await getFeed(c.env, getConfig(c.env), q));
  })
  .get("/search", publicRoute, rateLimit("RL_SEARCH"), zValidator("query", SearchQuery, validationHook), async (c) => {
    // Not CDN-cached: unbounded query strings would just fill the cache.
    const { q, lang } = c.req.valid("query");
    const rows = await postsRepo.searchPublished(drizzle(c.env.DB), q);
    return c.json({ items: rows.map((p) => toCard(p, lang, getConfig(c.env).SHARE_BASE_URL)) });
  })
  .get("/config", publicRoute, (c) => {
    c.header("Cache-Control", "public, s-maxage=600");
    return c.json({
      min_app_version: "1.0.0",
      tabs: ["feed", "video", "domestic", "international", "nxtspot"],
      ad_every_n_cards: 6,
      nxtspot_every_n_cards: 8,
    });
  })
  .post(
    "/auth/firebase",
    publicRoute,
    rateLimit("RL_AUTH"),
    zValidator("json", FirebaseExchange, validationHook),
    () => {
      throw new NotBuiltYet("T05: verifyFirebaseIdToken → upsert user → open session → issue tokens");
    },
  )
  .post("/auth/refresh", publicRoute, rateLimit("RL_AUTH"), zValidator("json", Refresh, validationHook), () => {
    throw new NotBuiltYet("T05: rotate refresh token; on reuse revoke the whole family");
  })
  .post("/auth/logout", currentUser, () => {
    throw new NotBuiltYet("T05: revoke session (claims.sid) in D1 + KV revocation list");
  })
  .get("/me", currentUser, (c) => c.json({ id: claimsOf(c).sub }))
  .delete("/me", currentUser, () => {
    throw new NotBuiltYet("T31: soft-delete user, revoke all sessions, purge after 30 days");
  });
