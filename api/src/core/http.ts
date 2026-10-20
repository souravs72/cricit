import type { Context } from "hono";
import { createMiddleware } from "hono/factory";

import type { AppEnv } from "./auth";
import { RateLimited, ValidationFailed } from "./errors";

/** Uses Cloudflare's cf-ray when present; echoed back as X-Request-ID and put on every log line. */
export const requestId = createMiddleware<AppEnv>(async (c, next) => {
  c.set("requestId", c.req.header("cf-ray") ?? crypto.randomUUID().replaceAll("-", ""));
  await next();
  c.header("X-Request-ID", c.get("requestId"));
});

export const securityHeaders = createMiddleware<AppEnv>(async (c, next) => {
  await next();
  c.header("X-Content-Type-Options", "nosniff");
  c.header("Referrer-Policy", "strict-origin-when-cross-origin");
  c.header("X-Frame-Options", "DENY");
  c.header("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
});

const MAX_BODY_BYTES = 1_000_000;
export const bodyLimit = createMiddleware<AppEnv>(async (c, next) => {
  const len = Number(c.req.header("content-length") ?? 0);
  if (len > MAX_BODY_BYTES) throw new ValidationFailed("Request body too large");
  await next();
});

export const clientIp = (c: Context<AppEnv>) => c.req.header("cf-connecting-ip") ?? "local";

type LimiterName = "RL_PUBLIC" | "RL_SEARCH" | "RL_AUTH" | "RL_ADMIN";

/** Cloudflare's native rate limiter (per location, per key). Key defaults to the client IP. */
export function rateLimit(binding: LimiterName, key: (c: Context<AppEnv>) => string = clientIp) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const { success } = await c.env[binding].limit({ key: `${binding}:${key(c)}` });
    if (!success) throw new RateLimited("Too many requests. Try again in a minute.");
    await next();
  });
}

/** zValidator hook: map failures onto our error shape with the offending field. */
export function validationHook(result: {
  success: boolean;
  error?: { issues: { path: PropertyKey[]; message: string }[] };
}) {
  if (!result.success) {
    const issue = result.error?.issues[0];
    throw new ValidationFailed(issue?.message ?? "Invalid input", issue?.path.map(String).join(".") || undefined);
  }
}
