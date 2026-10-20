/**
 * Worker entry: HTTP (Hono app), Cron Triggers, Queue consumer, and the ProcessArticle Workflow.
 *
 * Ingestion flow: cron (every 2 min) → enqueue one message per due source → queue consumer fetches
 * the feed and starts one ProcessArticle Workflow per new item (instance id = URL hash).
 */
import { createApp } from "./app";
import { getConfig } from "./core/config";

export { ProcessArticle } from "./workflows/process-article";

export interface IngestMessage {
  kind: "fetch_source";
  sourceId: string;
}

const app = createApp();

export default {
  fetch: app.fetch,

  async scheduled(controller, env, ctx) {
    getConfig(env); // fail fast on misconfiguration
    if (controller.cron === "*/2 * * * *") {
      // T10: select active sources whose interval has elapsed, then:
      // await env.INGEST_QUEUE.sendBatch(due.map((s) => ({ body: { kind: "fetch_source", sourceId: s.id } })));
      return;
    }
    // 03:00 IST: T26 rollups, archive posts older than 30 days, purge expired sessions and ads.
    ctx.waitUntil(Promise.resolve());
  },

  async queue(batch, env) {
    for (const msg of batch.messages) {
      try {
        // T10: load source → fetchRss → for each new item:
        // await env.PROCESS_ARTICLE.create({ id: urlHash, params: {...} })  (duplicate ids are rejected)
        void env;
        msg.ack();
      } catch (e) {
        console.error(JSON.stringify({ level: "error", event: "ingest_failed", body: msg.body, message: String(e) }));
        msg.retry({ delaySeconds: 60 * msg.attempts });
      }
    }
  },
} satisfies ExportedHandler<Env, IngestMessage>;
