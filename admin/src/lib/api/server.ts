import "server-only";
import { env } from "@/lib/env";
import { accessToken } from "@/lib/session";

/** Error shape returned by the FastAPI backend: {"error": {code, message, request_id, field?}} */
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public requestId?: string,
    public field?: string,
  ) {
    super(message);
  }
}

/**
 * Call the backend from server components and route handlers.
 * T18 adds silent refresh on 401 (single-flight) before giving up.
 */
export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = await accessToken();
  const res = await fetch(`${env.API_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
    cache: "no-store",
  });
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    const err = body?.error ?? {};
    throw new ApiError(
      res.status,
      err.code ?? "http_error",
      err.message ?? res.statusText,
      err.request_id,
      err.field,
    );
  }
  return (res.status === 204 ? undefined : await res.json()) as T;
}

/** Load a newsroom list; send the editor back to login on 401. */
export async function loadOrLogin<T>(path: string): Promise<{ data: T | null; error: string | null }> {
  try {
    return { data: await apiFetch<T>(path), error: null };
  } catch (e) {
    const { redirect } = await import("next/navigation");
    if (e instanceof ApiError && e.status === 401) redirect("/login");
    const message = e instanceof ApiError ? e.message : "Could not load this page.";
    return { data: null, error: message };
  }
}
