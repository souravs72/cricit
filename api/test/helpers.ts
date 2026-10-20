import { env } from "cloudflare:workers";

import { createApp } from "../src/app";
import { getConfig } from "../src/core/config";
import { permissionsFor, type Role } from "../src/core/permissions";
import { issueAccessToken } from "../src/core/security";

export const app = createApp();
export const cfg = () => getConfig(env);

export function call(path: string, init: RequestInit = {}) {
  return app.request(path, init, env);
}

export async function tokenFor(role?: Role): Promise<string> {
  if (!role) return issueAccessToken(cfg(), { subject: "u1", sessionId: "s1", typ: "user" });
  return issueAccessToken(cfg(), { subject: "a1", sessionId: "s2", typ: "admin", permissions: permissionsFor(role) });
}

export const bearer = (token: string) => ({ headers: { Authorization: `Bearer ${token}` } });
