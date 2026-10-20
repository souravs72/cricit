/** Admin API (/admin/v1). Never cached. Every write must also write audit_log (T07). */
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { z } from "zod";

import { claimsOf, currentAdmin, publicRoute, requirePermission, type AppEnv } from "../core/auth";
import { NotBuiltYet } from "../core/errors";
import { rateLimit, validationHook } from "../core/http";
import { Permission } from "../core/permissions";

const Login = z.object({ email: z.email(), password: z.string().min(12).max(200) });
const Totp = z.object({ challenge_id: z.string().min(1), code: z.string().regex(/^(\d{6}|[0-9a-f]{6}-[0-9a-f]{6})$/) });

export const admin = new Hono<AppEnv>()
  .use("*", async (c, next) => {
    await next();
    c.header("Cache-Control", "no-store");
  })
  .post("/auth/login", publicRoute, rateLimit("RL_AUTH"), zValidator("json", Login, validationHook), () => {
    throw new NotBuiltYet("T06: Argon2id check, lockout after 5 failures, return TOTP challenge");
  })
  .post("/auth/totp", publicRoute, rateLimit("RL_AUTH"), zValidator("json", Totp, validationHook), () => {
    throw new NotBuiltYet("T06: verify TOTP or recovery code, open admin session, issue tokens");
  })
  .get("/me", currentAdmin, (c) => {
    const claims = claimsOf(c);
    return c.json({ id: claims.sub, permissions: claims.perms });
  })
  .get("/sources", requirePermission(Permission.SOURCES_MANAGE), rateLimit("RL_ADMIN"), () => {
    throw new NotBuiltYet("T09: list sources with health status");
  });
