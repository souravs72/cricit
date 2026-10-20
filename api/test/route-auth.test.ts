/** Deny by default: every route must declare an auth middleware from src/core/auth.ts. */
import { describe, expect, it } from "vitest";

import { isAuthMiddleware } from "../src/core/auth";
import { app, bearer, call, tokenFor } from "./helpers";

describe("deny by default", () => {
  it("every route declares an auth middleware", () => {
    const byRoute = new Map<string, unknown[]>();
    for (const r of app.routes) {
      if (r.method === "ALL") continue; // app.use() middleware, not an endpoint
      const key = `${r.method} ${r.path}`;
      byRoute.set(key, [...(byRoute.get(key) ?? []), r.handler]);
    }
    const missing = [...byRoute].filter(([, handlers]) => !handlers.some(isAuthMiddleware)).map(([k]) => k);
    expect(byRoute.size).toBeGreaterThan(5);
    expect(missing).toEqual([]);
  });
});

describe("authentication and authorization", () => {
  it("rejects user routes without a token, with our error shape", async () => {
    const res = await call("/v1/me");
    expect(res.status).toBe(401);
    const body = (await res.json()) as { error: { code: string; request_id: string } };
    expect(body.error.code).toBe("unauthorized");
    expect(body.error.request_id).toBeTruthy();
  });

  it("accepts a valid user token", async () => {
    const res = await call("/v1/me", bearer(await tokenFor()));
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ id: "u1" });
  });

  it("rejects a user token on admin routes", async () => {
    expect((await call("/admin/v1/me", bearer(await tokenFor()))).status).toBe(401);
  });

  it("enforces permissions by role", async () => {
    expect((await call("/admin/v1/sources", bearer(await tokenFor("viewer")))).status).toBe(403);
    expect((await call("/admin/v1/sources", bearer(await tokenFor("editor")))).status).toBe(501); // allowed; built in T09
  });

  it("validates input with the field name", async () => {
    const res = await call("/v1/auth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: "short" }),
    });
    expect(res.status).toBe(422);
    expect(((await res.json()) as { error: { field: string } }).error.field).toBe("refresh_token");
  });

  it("sends security headers, a request id and no-store on admin responses", async () => {
    const res = await call("/health");
    expect(res.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(res.headers.get("X-Request-ID")).toBeTruthy();
    const adminRes = await call("/admin/v1/me", bearer(await tokenFor("viewer")));
    expect(adminRes.headers.get("Cache-Control")).toBe("no-store");
  });

  it("returns our 404 shape for unknown endpoints", async () => {
    const res = await call("/v1/nope");
    expect(res.status).toBe(404);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe("not_found");
  });
});
