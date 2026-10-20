import { z } from "zod";

/**
 * Typed, validated view of `env` vars and secrets. Parsed once per isolate.
 * Outside local/test, a missing secret is a startup error, not a runtime surprise.
 */
const schema = z
  .object({
    ENV: z.enum(["local", "test", "staging", "production"]).default("local"),
    JWT_ISSUER: z.string().min(1).default("cricit"),
    JWT_KEY_ID: z.string().min(1).default("k1"),
    JWT_PRIVATE_KEY: z.string().default(""),
    JWT_PUBLIC_KEYS: z.string().default(""),
    TOTP_ENCRYPTION_KEY: z.string().default(""),
    ADMIN_ORIGIN: z.string().url(),
    SHARE_BASE_URL: z.string().url(),
    FIREBASE_PROJECT_ID: z.string().min(1),
    FEED_PAGE_SIZE: z.coerce.number().int().min(5).max(50).default(20),
    LLM_API_KEY: z.string().default(""),
    YOUTUBE_API_KEY: z.string().default(""),
  })
  .superRefine((cfg, ctx) => {
    if (cfg.ENV === "staging" || cfg.ENV === "production") {
      for (const key of ["JWT_PRIVATE_KEY", "JWT_PUBLIC_KEYS", "TOTP_ENCRYPTION_KEY", "LLM_API_KEY"] as const) {
        if (!cfg[key]) ctx.addIssue({ code: "custom", path: [key], message: `${key} is required in ${cfg.ENV}` });
      }
    }
  });

export type Config = z.infer<typeof schema> & {
  userAccessTtlS: number;
  adminAccessTtlS: number;
  userSessionSlidingMs: number;
  userSessionAbsoluteMs: number;
  adminSessionIdleMs: number;
  adminSessionAbsoluteMs: number;
};

const cache = new WeakMap<object, Config>();

export function getConfig(env: Env): Config {
  const hit = cache.get(env);
  if (hit) return hit;
  const parsed = schema.parse(env);
  const cfg: Config = {
    ...parsed,
    userAccessTtlS: 15 * 60,
    adminAccessTtlS: 10 * 60,
    userSessionSlidingMs: 30 * 24 * 3600_000,
    userSessionAbsoluteMs: 90 * 24 * 3600_000,
    adminSessionIdleMs: 30 * 60_000,
    adminSessionAbsoluteMs: 12 * 3600_000,
  };
  cache.set(env, cfg);
  return cfg;
}
