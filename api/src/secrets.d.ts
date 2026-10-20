// Secrets are not in wrangler.jsonc, so `wrangler types` cannot see them. Merged into the generated
// base interface so both `Env` and `Cloudflare.Env` (used by `cloudflare:workers`) include them.
interface __BaseEnv_Env {
  JWT_PRIVATE_KEY: string;
  /** "k1=<PEM>||k2=<PEM>" — every public key still allowed to verify tokens. */
  JWT_PUBLIC_KEYS: string;
  TOTP_ENCRYPTION_KEY: string;
  LLM_API_KEY: string;
  YOUTUBE_API_KEY: string;
}
