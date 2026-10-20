import "server-only";
import { cookies } from "next/headers";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "./security";

type TokenPair = { access_token: string; refresh_token: string; expires_in: number };

const base = {
  httpOnly: true,
  secure: true, // required by the __Host- prefix; localhost is treated as secure by browsers
  sameSite: "strict" as const,
  path: "/",
};

export async function setSession(tokens: TokenPair) {
  const jar = await cookies();
  jar.set(ACCESS_COOKIE, tokens.access_token, { ...base, maxAge: tokens.expires_in });
  jar.set(REFRESH_COOKIE, tokens.refresh_token, { ...base, maxAge: 12 * 60 * 60 });
}

export async function clearSession() {
  const jar = await cookies();
  jar.delete(ACCESS_COOKIE);
  jar.delete(REFRESH_COOKIE);
}

export async function accessToken(): Promise<string | undefined> {
  return (await cookies()).get(ACCESS_COOKIE)?.value;
}
