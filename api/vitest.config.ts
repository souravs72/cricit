import { generateKeyPairSync, randomBytes } from "node:crypto";
import path from "node:path";

import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

function ecKeyPair() {
  const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  return {
    priv: privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
    pub: publicKey.export({ type: "spki", format: "pem" }).toString(),
  };
}

export default defineConfig({
  plugins: [
    cloudflareTest(async () => {
      const k1 = ecKeyPair();
      const k2 = ecKeyPair();
      return {
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          bindings: {
            ENV: "test",
            JWT_PRIVATE_KEY: k1.priv,
            JWT_KEY_ID: "k1",
            JWT_PUBLIC_KEYS: `k1=${k1.pub}||k2=${k2.pub}`,
            TEST_PRIVATE_KEY_K2: k2.priv,
            TOTP_ENCRYPTION_KEY: randomBytes(32).toString("base64"),
            TEST_MIGRATIONS: await readD1Migrations(path.join(__dirname, "migrations")),
          },
        },
      };
    }),
  ],
  test: {
    setupFiles: ["./test/apply-migrations.ts"],
  },
});
