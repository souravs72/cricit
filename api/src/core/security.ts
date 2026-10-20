/**
 * Token, password and 2FA primitives. Pure functions; services own state.
 *
 * - Access tokens: JWT ES256 with a `kid` header so keys can rotate.
 * - Refresh tokens / recovery codes / invites: random strings; only SHA-256 hashes are stored.
 * - Passwords: Argon2id (@noble/hashes, pure JS; OWASP m=19 MiB, t=2, p=1; ~300 ms).
 *   Workers forbid runtime WebAssembly compilation, so WASM hashers like hash-wasm cannot run here.
 * - Admin 2FA: TOTP (RFC 6238); secrets encrypted at rest with AES-GCM.
 */
import { argon2idAsync } from "@noble/hashes/argon2.js";
import { SignJWT, decodeProtectedHeader, errors, importPKCS8, importSPKI, jwtVerify, type CryptoKey } from "jose";
import { Secret, TOTP } from "otpauth";

import type { Config } from "./config";
import { Unauthorized } from "./errors";
import { randomToken, sha256Hex } from "./ids";

export type PrincipalType = "user" | "admin";

export interface TokenClaims {
  sub: string;
  sid: string;
  typ: PrincipalType;
  jti: string;
  exp: number;
  perms: string[];
}

const ALG = "ES256";
const pem = (s: string) => s.replaceAll("\\n", "\n").trim();

const privateKeys = new Map<string, Promise<CryptoKey>>();
const publicKeys = new Map<string, Promise<CryptoKey>>();

function privateKey(cfg: Config): Promise<CryptoKey> {
  const k = cfg.JWT_PRIVATE_KEY;
  if (!privateKeys.has(k)) privateKeys.set(k, importPKCS8(pem(k), ALG));
  return privateKeys.get(k)!;
}

function publicKeyFor(cfg: Config, kid: string): Promise<CryptoKey> | undefined {
  for (const pair of cfg.JWT_PUBLIC_KEYS.split("||").filter(Boolean)) {
    const [id, ...rest] = pair.split("=");
    if (id?.trim() !== kid) continue;
    const key = rest.join("=");
    if (!publicKeys.has(key)) publicKeys.set(key, importSPKI(pem(key), ALG));
    return publicKeys.get(key);
  }
  return undefined;
}

export async function issueAccessToken(
  cfg: Config,
  args: { subject: string; sessionId: string; typ: PrincipalType; permissions?: readonly string[] },
): Promise<string> {
  const ttl = args.typ === "admin" ? cfg.adminAccessTtlS : cfg.userAccessTtlS;
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({
    sid: args.sessionId,
    typ: args.typ,
    ...(args.permissions?.length ? { perms: args.permissions } : {}),
  })
    .setProtectedHeader({ alg: ALG, kid: cfg.JWT_KEY_ID })
    .setIssuer(cfg.JWT_ISSUER)
    .setSubject(args.subject)
    .setIssuedAt(now)
    .setExpirationTime(now + ttl)
    .setJti(crypto.randomUUID())
    .sign(await privateKey(cfg));
}

export async function decodeAccessToken(cfg: Config, token: string, expected: PrincipalType): Promise<TokenClaims> {
  let kid: string | undefined;
  try {
    kid = decodeProtectedHeader(token).kid;
  } catch {
    throw new Unauthorized("Invalid token");
  }
  const key = kid ? publicKeyFor(cfg, kid) : undefined;
  if (!key) throw new Unauthorized("Unknown signing key");
  try {
    const { payload } = await jwtVerify(token, await key, {
      issuer: cfg.JWT_ISSUER,
      algorithms: [ALG],
      requiredClaims: ["exp", "iat", "sub", "sid", "typ", "jti"],
    });
    if (payload.typ !== expected) throw new Unauthorized("Wrong token type");
    return {
      sub: payload.sub!,
      sid: String(payload.sid),
      typ: payload.typ as PrincipalType,
      jti: payload.jti!,
      exp: payload.exp!,
      perms: Array.isArray(payload.perms) ? payload.perms.map(String) : [],
    };
  } catch (e) {
    if (e instanceof Unauthorized) throw e;
    if (e instanceof errors.JWTExpired) throw new Unauthorized("Session expired");
    throw new Unauthorized("Invalid token");
  }
}

/** Returns [token for the client, hash to store]. */
export async function newRefreshToken(): Promise<[string, string]> {
  const token = randomToken(32);
  return [token, await sha256Hex(token)];
}

export const hashToken = sha256Hex;

export async function tokensMatch(storedHash: string, presented: string): Promise<boolean> {
  const enc = new TextEncoder();
  return constantTimeEqual(enc.encode(storedHash), enc.encode(await sha256Hex(presented)));
}

const ARGON = { m: 19_456, t: 2, p: 1, dkLen: 32 } as const;

const b64 = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes)).replace(/=+$/, "");
const unb64 = (s: string) => Uint8Array.from(atob(s + "=".repeat((4 - (s.length % 4)) % 4)), (c) => c.charCodeAt(0));

function constantTimeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i]! ^ b[i]!;
  return diff === 0;
}

/** Returns a standard PHC string: $argon2id$v=19$m=…,t=…,p=…$salt$hash */
export async function hashPassword(password: string): Promise<string> {
  if (password.length < 12) throw new Error("Password must be at least 12 characters");
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const hash = await argon2idAsync(password, salt, ARGON);
  return `$argon2id$v=19$m=${ARGON.m},t=${ARGON.t},p=${ARGON.p}$${b64(salt)}$${b64(hash)}`;
}

export async function verifyPassword(stored: string, password: string): Promise<boolean> {
  const m = /^\$argon2id\$v=19\$m=(\d+),t=(\d+),p=(\d+)\$([A-Za-z0-9+/]+)\$([A-Za-z0-9+/]+)$/.exec(stored);
  if (!m) return false;
  const expected = unb64(m[5]!);
  const actual = await argon2idAsync(password, unb64(m[4]!), {
    m: Number(m[1]),
    t: Number(m[2]),
    p: Number(m[3]),
    dkLen: expected.length,
  });
  return constantTimeEqual(actual, expected);
}

/** True when a stored hash uses weaker parameters than today's; rehash after a successful login. */
export function passwordNeedsRehash(stored: string): boolean {
  return !stored.startsWith(`$argon2id$v=19$m=${ARGON.m},t=${ARGON.t},p=${ARGON.p}$`);
}

export function newTotpSecret(): string {
  return new Secret({ size: 20 }).base32;
}

function totp(secret: string, label = "admin"): TOTP {
  return new TOTP({
    issuer: "CRICIT Newsroom",
    label,
    algorithm: "SHA1",
    digits: 6,
    period: 30,
    secret: Secret.fromBase32(secret),
  });
}

export function totpUri(secret: string, email: string): string {
  return totp(secret, email).toString();
}

/** Accepts the previous/next 30 s step to absorb clock drift. */
export function verifyTotp(secret: string, code: string, at: number = Date.now()): boolean {
  if (!/^\d{6}$/.test(code)) return false;
  return totp(secret).validate({ token: code, timestamp: at, window: 1 }) !== null;
}

export function totpAt(secret: string, at: number): string {
  return totp(secret).generate({ timestamp: at });
}

/** Returns [codes shown once to the admin, hashes to store]. */
export async function newRecoveryCodes(count = 10): Promise<[string[], string[]]> {
  const hex = (n: number) =>
    [...crypto.getRandomValues(new Uint8Array(n))].map((b) => b.toString(16).padStart(2, "0")).join("");
  const codes = Array.from({ length: count }, () => `${hex(3)}-${hex(3)}`);
  return [codes, await Promise.all(codes.map(sha256Hex))];
}

async function aesKey(b64: string): Promise<globalThis.CryptoKey> {
  const raw = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  if (raw.length !== 32) throw new Error("TOTP_ENCRYPTION_KEY must be 32 bytes (base64)");
  return crypto.subtle.importKey("raw", raw, "AES-GCM", false, ["encrypt", "decrypt"]);
}

/** AES-256-GCM; output = base64(iv || ciphertext). */
export async function encryptSecret(plain: string, keyB64: string): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ct = new Uint8Array(
    await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await aesKey(keyB64), new TextEncoder().encode(plain)),
  );
  const out = new Uint8Array(iv.length + ct.length);
  out.set(iv);
  out.set(ct, iv.length);
  return btoa(String.fromCharCode(...out));
}

export async function decryptSecret(enc: string, keyB64: string): Promise<string> {
  const data = Uint8Array.from(atob(enc), (c) => c.charCodeAt(0));
  const pt = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: data.slice(0, 12) },
    await aesKey(keyB64),
    data.slice(12),
  );
  return new TextDecoder().decode(pt);
}
