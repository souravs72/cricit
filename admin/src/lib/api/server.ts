import "server-only";
import { getCloudflareContext } from "@opennextjs/cloudflare";
import { env } from "@/lib/env";
import { accessToken } from "@/lib/session";

/** Error shape returned by the CRICIT API: {"error": {code, message, request_id, field?}} */
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

type ServiceBinding = { fetch(request: Request): Promise<Response> };

/**
 * Reach the API Worker. On Cloudflare this goes through the API service binding (Worker-to-Worker);
 * under `next dev` there is no binding, so it falls back to API_BASE_URL (e.g. `wrangler dev` on :8787).
 */
export async function backendFetch(path: string, init: RequestInit): Promise<Response> {
  let binding: ServiceBinding | undefined;
  try {
    binding = (getCloudflareContext().env as { API?: ServiceBinding }).API;
  } catch {
    binding = undefined;
  }
  if (binding) return binding.fetch(new Request(`https://api.internal${path}`, init));
  return fetch(`${env.API_BASE_URL}${path}`, init);
}

/**
 * Call the backend from server components and route handlers.
 * T18 adds silent refresh on 401 (single-flight) before giving up.
 */
export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = await accessToken();
  const res = await backendFetch(path, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
    cache: "no-store",
  });
  if (!res.ok) {
    const body = (await res.json().catch(() => null)) as {
      error?: { code?: string; message?: string; request_id?: string; field?: string };
    } | null;
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
