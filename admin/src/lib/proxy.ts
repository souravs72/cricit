/** Browser → /api/proxy → FastAPI. Tokens stay in HttpOnly cookies.

Callers: review-queue.tsx, sources-manager.tsx.
API: POST/PATCH /api/proxy/admin/v1/posts/{id}/publish|reject and /sources.
User: "Check what is tobe built now into this - build it"
*/

export async function proxyJson<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(`/api/proxy/${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init.headers },
  });
  const body = (await res.json().catch(() => ({}))) as {
    error?: { message?: string };
  };
  if (!res.ok) {
    throw new Error(body.error?.message ?? "Request failed");
  }
  return body as T;
}
