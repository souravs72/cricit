import { defineCloudflareConfig } from "@opennextjs/cloudflare";

// The newsroom renders per request (no ISR), so the default (no incremental cache) is right.
export default defineCloudflareConfig();
