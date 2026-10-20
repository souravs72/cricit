/**
 * Auth middleware. Every route must use exactly one of these (test/route-auth.test.ts enforces it):
 * - `publicRoute`             no login (feeds, config, search, health)
 * - `optionalUser`            works logged out; claims attached when a valid user token is sent
 * - `currentUser`             app user required
 * - `currentAdmin`            any signed-in admin
 * - `requirePermission(p)`    admin with permission p
 *
 * `user_id` must always come from claims.sub, never from the request body or query.
 * Session revocation (logout, refresh reuse) is checked against KV in T05/T06.
 */
import type { Context } from "hono";
import { createMiddleware } from "hono/factory";

import { getConfig } from "./config";
import { Forbidden, Unauthorized } from "./errors";
import type { Permission } from "./permissions";
import { decodeAccessToken, type TokenClaims } from "./security";

export type AppEnv = {
  Bindings: Env;
  Variables: { requestId: string; claims: TokenClaims | null };
};

const AUTH_MIDDLEWARE = new WeakSet<object>();
function mark<T extends object>(mw: T): T {
  AUTH_MIDDLEWARE.add(mw);
  return mw;
}
export const isAuthMiddleware = (h: unknown): boolean => typeof h === "function" && AUTH_MIDDLEWARE.has(h);

function bearer(c: Context<AppEnv>): string | null {
  const h = c.req.header("authorization");
  return h?.startsWith("Bearer ") ? h.slice(7).trim() || null : null;
}

export const publicRoute = mark(
  createMiddleware<AppEnv>(async (c, next) => {
    c.set("claims", null);
    await next();
  }),
);

export const optionalUser = mark(
  createMiddleware<AppEnv>(async (c, next) => {
    const token = bearer(c);
    c.set("claims", token ? await decodeAccessToken(getConfig(c.env), token, "user") : null);
    await next();
  }),
);

export const currentUser = mark(
  createMiddleware<AppEnv>(async (c, next) => {
    const token = bearer(c);
    if (!token) throw new Unauthorized("Sign in to continue");
    c.set("claims", await decodeAccessToken(getConfig(c.env), token, "user"));
    await next();
  }),
);

// The admin's Next.js server forwards the token as a bearer header; browsers never hold it.
export const currentAdmin = mark(
  createMiddleware<AppEnv>(async (c, next) => {
    const token = bearer(c);
    if (!token) throw new Unauthorized("Admin sign-in required");
    c.set("claims", await decodeAccessToken(getConfig(c.env), token, "admin"));
    await next();
  }),
);

export function requirePermission(permission: Permission) {
  return mark(
    createMiddleware<AppEnv>(async (c, next) => {
      const token = bearer(c);
      if (!token) throw new Unauthorized("Admin sign-in required");
      const claims = await decodeAccessToken(getConfig(c.env), token, "admin");
      if (!claims.perms.includes(permission)) throw new Forbidden(`Missing permission: ${permission}`);
      c.set("claims", claims);
      await next();
    }),
  );
}

export function claimsOf(c: Context<AppEnv>): TokenClaims {
  const claims = c.get("claims");
  if (!claims) throw new Unauthorized("Sign in to continue");
  return claims;
}
