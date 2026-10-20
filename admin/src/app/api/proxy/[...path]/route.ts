import { NextResponse, type NextRequest } from "next/server";
import { env } from "@/lib/env";
import { isAllowedProxyPath } from "@/lib/security";
import { accessToken } from "@/lib/session";

/** Browser → Next.js → FastAPI. Attaches the admin token server-side; the browser never sees it. */
async function forward(req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  const path = (await params).path.join("/");
  if (!isAllowedProxyPath(path)) {
    return NextResponse.json({ error: { code: "not_found", message: "Unknown endpoint" } }, { status: 404 });
  }
  const token = await accessToken();
  const target = `${env.API_BASE_URL}/${path}${req.nextUrl.search}`;
  const res = await fetch(target, {
    method: req.method,
    headers: {
      "Content-Type": req.headers.get("content-type") ?? "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(req.headers.get("idempotency-key")
        ? { "Idempotency-Key": req.headers.get("idempotency-key")! }
        : {}),
    },
    body: ["GET", "HEAD"].includes(req.method) ? undefined : await req.text(),
    cache: "no-store",
  });
  return new NextResponse(res.body, {
    status: res.status,
    headers: { "Content-Type": res.headers.get("content-type") ?? "application/json" },
  });
}

export { forward as GET, forward as POST, forward as PATCH, forward as DELETE };
