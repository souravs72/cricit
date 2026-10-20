/**
 * Verify a Firebase Auth ID token without the Admin SDK (which needs Node): it is a standard
 * RS256 JWT signed by Google's securetoken keys. Used by T05's /v1/auth/firebase exchange.
 */
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "jose";

import { Unauthorized } from "./errors";

const GOOGLE_JWKS = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
  { cacheMaxAge: 6 * 3600_000 },
);

export interface FirebaseIdentity {
  uid: string;
  phone: string;
  authTime: number;
}

/** maxAuthAgeS: reject sign-ins older than this (the app exchanges right after OTP). */
export async function verifyFirebaseIdToken(
  idToken: string,
  projectId: string,
  opts: { keys?: JWTVerifyGetKey; maxAuthAgeS?: number; now?: number } = {},
): Promise<FirebaseIdentity> {
  const now = opts.now ?? Math.floor(Date.now() / 1000);
  try {
    const { payload } = await jwtVerify(idToken, opts.keys ?? GOOGLE_JWKS, {
      algorithms: ["RS256"],
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
      currentDate: new Date(now * 1000),
    });
    const authTime = Number(payload.auth_time);
    if (!payload.sub || !Number.isFinite(authTime) || authTime > now) throw new Unauthorized("Invalid sign-in");
    if (now - authTime > (opts.maxAuthAgeS ?? 300)) throw new Unauthorized("Sign-in too old; verify your number again");
    const phone = typeof payload.phone_number === "string" ? payload.phone_number : "";
    if (!phone) throw new Unauthorized("Phone sign-in required");
    return { uid: payload.sub, phone, authTime };
  } catch (e) {
    if (e instanceof Unauthorized) throw e;
    throw new Unauthorized("Invalid sign-in");
  }
}
