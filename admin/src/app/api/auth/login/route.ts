import { NextResponse } from "next/server";
import { z } from "zod";
import { ApiError, apiFetch } from "@/lib/api/server";

const body = z.object({ email: z.string().email(), password: z.string().min(12) });

/** First login step: password check. Returns a TOTP challenge, never tokens. */
export async function POST(req: Request) {
  const parsed = body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: "validation_failed", message: "Check your email and password" } },
      { status: 422 },
    );
  }
  try {
    const challenge = await apiFetch<{ challenge_id: string }>("/admin/v1/auth/login", {
      method: "POST",
      body: JSON.stringify(parsed.data),
    });
    return NextResponse.json(challenge);
  } catch (e) {
    const err = e instanceof ApiError ? e : new ApiError(500, "internal_error", "Sign-in failed");
    return NextResponse.json({ error: { code: err.code, message: err.message } }, { status: err.status });
  }
}
