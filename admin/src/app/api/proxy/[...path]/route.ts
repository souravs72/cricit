import { NextResponse, type NextRequest } from "next/server";
import { backendFetch } from "@/lib/api/server";
import { rejectCrossSite } from "@/lib/guard";
import { isAllowedProxyPath } from "@/lib/security";
import { accessToken } from "@/lib/session";

/** Browser → Next.js → API Worker. Attaches the admin token server-side; the browser never sees it. */
async function forward(req: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  const blocked = rejectCrossSite(req);
  if (blocked) return blocked;
  const path = (await params).path.join("/");
  if (!isAllowedProxyPath(path)) {
    return NextResponse.json({ error: { code: "not_found", message: "Unknown endpoint" } }, { status: 404 });
  }
  const token = await accessToken();
  if (!token) {
    return NextResponse.json(
      { error: { code: "unauthorized", message: "Sign in to continue" } },
      { status: 401 },
    );
  }
  const idempotencyKey = req.headers.get("idempotency-key");
  const res = await backendFetch(`/${path}${req.nextUrl.search}`, {
    method: req.method,
    headers: {
      "Content-Type": req.headers.get("content-type") ?? "application/json",
      Authorization: `Bearer ${token}`,
      ...(idempotencyKey ? { "Idempotency-Key": idempotencyKey } : {}),
    },
    body: ["GET", "HEAD"].includes(req.method) ? undefined : await req.text(),
  });
  return new NextResponse(res.body, {
    status: res.status,
    headers: { "Content-Type": res.headers.get("content-type") ?? "application/json" },
  });
}

export { forward as GET, forward as POST, forward as PATCH, forward as DELETE };
