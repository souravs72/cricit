import { NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, apiFetch } from "@/lib/api/server";
import { rejectCrossSite } from "@/lib/guard";
import { setSession } from "@/lib/session";

const body = z.object({ challenge_id: z.string().min(1), code: z.string().min(6).max(13) });

/** Second login step: exchange the TOTP code for tokens and store them in HttpOnly cookies. */
export async function POST(req: Request) {
  const blocked = rejectCrossSite(req);
  if (blocked) return blocked;
  const parsed = body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: "validation_failed", message: "Enter the 6-digit code" } },
      { status: 422 },
    );
  }
  try {
    const tokens = await apiFetch<{ access_token: string; refresh_token: string; expires_in: number }>(
      "/admin/v1/auth/totp",
      { method: "POST", body: JSON.stringify(parsed.data) },
    );
    await setSession(tokens);
    return NextResponse.json({ ok: true });
  } catch (e) {
    const err = e instanceof ApiError ? e : new ApiError(500, "internal_error", "Sign-in failed");
    return NextResponse.json({ error: { code: err.code, message: err.message } }, { status: err.status });
  }
}
