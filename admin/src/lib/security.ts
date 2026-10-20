/** Pure helpers shared by middleware and route handlers (no Node-only imports). */

export const ACCESS_COOKIE = "__Host-cricit_at";
export const REFRESH_COOKIE = "__Host-cricit_rt";

/** Paths an anonymous visitor may open. Everything else needs a session. */
const PUBLIC_PATHS = ["/login", "/api/auth/login", "/api/auth/totp"];

export function isPublicPath(pathname: string): boolean {
  return PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

/**
 * CSRF defence for mutating requests, on top of SameSite=Strict cookies:
 * the Origin header must match the app's own origin exactly.
 */
export function isSameOrigin(method: string, origin: string | null, host: string | null): boolean {
  if (["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase())) return true;
  if (!origin || !host) return false;
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}

/** Only these backend prefixes may be reached through /api/proxy. */
export function isAllowedProxyPath(path: string): boolean {
  return /^admin\/v1\/[a-z0-9/_-]+$/i.test(path) && !path.includes("..");
}
