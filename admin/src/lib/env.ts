import "server-only";
import { z } from "zod";

/** Server-only configuration. Nothing here may be prefixed NEXT_PUBLIC_. */
const schema = z.object({
  // Only used when no API service binding exists (local `next dev` against `wrangler dev`).
  API_BASE_URL: z.string().url().default("http://localhost:8787"),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
});

export const env = schema.parse({
  API_BASE_URL: process.env.API_BASE_URL,
  NODE_ENV: process.env.NODE_ENV,
});
