import { NextResponse } from "next/server";
import { rejectCrossSite } from "@/lib/guard";
import { clearSession } from "@/lib/session";

/** T18: also call the backend to revoke the session before clearing cookies. */
export async function POST(req: Request) {
  const blocked = rejectCrossSite(req);
  if (blocked) return blocked;
  await clearSession();
  return NextResponse.redirect(new URL("/login", req.url), { status: 303 });
}
