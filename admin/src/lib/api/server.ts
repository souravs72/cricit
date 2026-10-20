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
