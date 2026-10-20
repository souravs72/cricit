import { env } from "cloudflare:workers";
import { decodeProtectedHeader, exportSPKI, generateKeyPair, SignJWT } from "jose";
import { describe, expect, it } from "vitest";

import { getConfig } from "../src/core/config";
import { verifyFirebaseIdToken } from "../src/core/firebase";
import {
  decodeAccessToken,
  decryptSecret,
  encryptSecret,
  hashPassword,
  issueAccessToken,
  newRecoveryCodes,
  newRefreshToken,
  newTotpSecret,
  tokensMatch,
  totpAt,
  verifyPassword,
  verifyTotp,
} from "../src/core/security";
import { cfg } from "./helpers";

describe("access tokens", () => {
  it("round-trips with the kid header", async () => {
    const token = await issueAccessToken(cfg(), { subject: "u1", sessionId: "s1", typ: "user" });
    const claims = await decodeAccessToken(cfg(), token, "user");
    expect(claims).toMatchObject({ sub: "u1", sid: "s1", typ: "user" });
    expect(decodeProtectedHeader(token).kid).toBe("k1");
  });

  it("rejects a user token where an admin token is required", async () => {
    const token = await issueAccessToken(cfg(), { subject: "u1", sessionId: "s1", typ: "user" });
    await expect(decodeAccessToken(cfg(), token, "admin")).rejects.toThrow("Wrong token type");
  });

  it("rejects expired tokens", async () => {
    const short = { ...cfg(), userAccessTtlS: -5 };
    const token = await issueAccessToken(short, { subject: "u1", sessionId: "s1", typ: "user" });
    await expect(decodeAccessToken(cfg(), token, "user")).rejects.toThrow("Session expired");
  });

  it("rejects tampered tokens", async () => {
    const [h, b, s] = (await issueAccessToken(cfg(), { subject: "u1", sessionId: "s1", typ: "user" })).split(".");
    await expect(decodeAccessToken(cfg(), `${h}.${b}x.${s}`, "user")).rejects.toThrow();
  });

  it("keeps old and new keys valid during rotation", async () => {
    const rotated = { ...cfg(), JWT_PRIVATE_KEY: env.TEST_PRIVATE_KEY_K2, JWT_KEY_ID: "k2" };
    const oldTok = await issueAccessToken(cfg(), { subject: "u1", sessionId: "s1", typ: "user" });
    const newTok = await issueAccessToken(rotated, { subject: "u2", sessionId: "s1", typ: "user" });
    expect((await decodeAccessToken(cfg(), oldTok, "user")).sub).toBe("u1");
    expect((await decodeAccessToken(cfg(), newTok, "user")).sub).toBe("u2");
  });

  it("rejects an unknown kid", async () => {
    const rogue = { ...cfg(), JWT_KEY_ID: "k9" };
    const token = await issueAccessToken(rogue, { subject: "u1", sessionId: "s1", typ: "user" });
    await expect(decodeAccessToken(cfg(), token, "user")).rejects.toThrow("Unknown signing key");
  });
});

describe("secrets at rest", () => {
  it("stores refresh tokens only as hashes", async () => {
    const [token, stored] = await newRefreshToken();
    expect(stored).not.toContain(token);
    expect(await tokensMatch(stored, token)).toBe(true);
    expect(await tokensMatch(stored, `${token}x`)).toBe(false);
  });

  it("hashes passwords with Argon2id", async () => {
    const stored = await hashPassword("correct horse battery");
    expect(stored.startsWith("$argon2id$")).toBe(true);
    expect(await verifyPassword(stored, "correct horse battery")).toBe(true);
    expect(await verifyPassword(stored, "wrong horse battery")).toBe(false);
    await expect(hashPassword("short")).rejects.toThrow();
  });

  it("verifies TOTP codes with one step of drift and rejects others", () => {
    const secret = newTotpSecret();
    const now = Date.UTC(2026, 9, 20, 12);
    expect(verifyTotp(secret, totpAt(secret, now), now)).toBe(true);
    expect(verifyTotp(secret, totpAt(secret, now - 30_000), now)).toBe(true);
    expect(verifyTotp(secret, totpAt(secret, now - 120_000), now)).toBe(false);
    expect(verifyTotp(secret, "12345a", now)).toBe(false);
  });

  it("encrypts TOTP secrets with AES-GCM", async () => {
    const secret = newTotpSecret();
    const enc = await encryptSecret(secret, env.TOTP_ENCRYPTION_KEY);
    expect(enc).not.toContain(secret);
    expect(await decryptSecret(enc, env.TOTP_ENCRYPTION_KEY)).toBe(secret);
  });

  it("issues ten distinct recovery codes", async () => {
    const [codes, hashes] = await newRecoveryCodes();
    expect(codes).toHaveLength(10);
    expect(new Set(hashes).size).toBe(10);
  });
});

describe("Firebase ID tokens", () => {
  const projectId = "cricit-test";
  const now = Math.floor(Date.UTC(2026, 9, 20, 12) / 1000);

  async function signed(claims: Record<string, unknown>, opts: { aud?: string } = {}) {
    const { privateKey, publicKey } = await generateKeyPair("RS256");
    const token = await new SignJWT(claims)
      .setProtectedHeader({ alg: "RS256", kid: "g1" })
      .setIssuer(`https://securetoken.google.com/${projectId}`)
      .setAudience(opts.aud ?? projectId)
      .setSubject("firebase-uid-1")
      .setIssuedAt(now - 10)
      .setExpirationTime(now + 3600)
      .sign(privateKey);
    expect(await exportSPKI(publicKey)).toContain("PUBLIC KEY");
    return { token, keys: async () => publicKey };
  }

  it("accepts a fresh phone sign-in", async () => {
    const { token, keys } = await signed({ auth_time: now - 20, phone_number: "+919800000000" });
    const id = await verifyFirebaseIdToken(token, projectId, { keys, now });
    expect(id).toMatchObject({ uid: "firebase-uid-1", phone: "+919800000000" });
  });

  it("rejects old sign-ins, other projects and missing phone numbers", async () => {
    const old = await signed({ auth_time: now - 3600, phone_number: "+919800000000" });
    await expect(verifyFirebaseIdToken(old.token, projectId, { keys: old.keys, now })).rejects.toThrow("too old");
    const other = await signed({ auth_time: now - 5, phone_number: "+919800000000" }, { aud: "someone-else" });
    await expect(verifyFirebaseIdToken(other.token, projectId, { keys: other.keys, now })).rejects.toThrow();
    const noPhone = await signed({ auth_time: now - 5 });
    await expect(verifyFirebaseIdToken(noPhone.token, projectId, { keys: noPhone.keys, now })).rejects.toThrow("Phone");
  });
});

describe("configuration", () => {
  it("refuses to run in production without secrets", () => {
    expect(() => getConfig({ ...env, ENV: "production", JWT_PRIVATE_KEY: "", LLM_API_KEY: "" } as Env)).toThrow(
      /required in production/,
    );
  });
});
