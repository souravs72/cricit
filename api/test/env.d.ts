// Test-only bindings added in vitest.config.ts.
interface __BaseEnv_Env {
  TEST_MIGRATIONS: import("cloudflare:test").D1Migration[];
  TEST_PRIVATE_KEY_K2: string;
}
