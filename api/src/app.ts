import { Hono } from "hono";
import { cors } from "hono/cors";

import { publicRoute, type AppEnv } from "./core/auth";
import { getConfig } from "./core/config";
import { errorBody, onError } from "./core/errors";
import { bodyLimit, requestId, securityHeaders } from "./core/http";
import { admin } from "./routes/admin";
import { v1 } from "./routes/v1";

export function createApp() {
  const app = new Hono<AppEnv>();

  app.use("*", requestId, securityHeaders, bodyLimit);
  app.use("/admin/*", async (c, next) => {
    const origin = getConfig(c.env).ADMIN_ORIGIN;
    return cors({
      origin,
      allowMethods: ["GET", "POST", "PATCH", "DELETE"],
      allowHeaders: ["Authorization", "Content-Type", "Idempotency-Key"],
      credentials: true,
    })(c, next);
  });

  app.get("/health", publicRoute, (c) => c.json({ status: "ok" }));
  app.get("/ready", publicRoute, async (c) => {
    await c.env.DB.prepare("SELECT 1").first();
    await c.env.CACHE.get("feed:version");
    return c.json({ status: "ready" });
  });

  app.route("/v1", v1);
  app.route("/admin/v1", admin);

  app.notFound((c) => c.json(errorBody(c, "not_found", "No such endpoint"), 404));
  app.onError(onError);
  return app;
}
