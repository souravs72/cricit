import "server-only";
import { NextResponse } from "next/server";
import { isSameOrigin } from "./security";

/**
 * CSRF defence for every mutating route handler (on top of SameSite=Strict cookies).
 * Done per handler instead of in middleware: OpenNext cannot run Node-runtime middleware, and
 * checks inside the handler cannot be skipped by middleware-bypass bugs.
 */
export function rejectCrossSite(req: Request): NextResponse | null {
  const host = req.headers.get("x-forwarded-host") ?? req.headers.get("host");
  if (isSameOrigin(req.method, req.headers.get("origin"), host)) return null;
  return NextResponse.json(
    { error: { code: "bad_origin", message: "Cross-site request blocked" } },
    { status: 403 },
  );
}
