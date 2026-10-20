import { NextResponse, type NextRequest } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE, isPublicPath, isSameOrigin } from "@/lib/security";

/**
 * Convenience gate only. The backend still rejects every request without a valid token,
 * so this is never the security boundary.
 */
export function proxy(req: NextRequest) {
  const { pathname } = req.nextUrl;

  if (
    pathname.startsWith("/api/") &&
    !isSameOrigin(req.method, req.headers.get("origin"), req.headers.get("host"))
  ) {
    return NextResponse.json(
      { error: { code: "bad_origin", message: "Cross-site request blocked" } },
      { status: 403 },
    );
  }

  if (isPublicPath(pathname)) return NextResponse.next();

  const signedIn = req.cookies.has(ACCESS_COOKIE) || req.cookies.has(REFRESH_COOKIE);
  if (!signedIn) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json(
        { error: { code: "unauthorized", message: "Sign in to continue" } },
        { status: 401 },
      );
    }
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|fonts/).*)"],
};
