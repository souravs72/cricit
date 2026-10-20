/**
 * One durable Workflow instance per article. The instance id is the article's URL hash, and
 * Cloudflare rejects a second instance with the same id, so an article is never processed twice
 * even if a queue message is redelivered. Each step retries on its own (T12–T16 fill them in).
 */
import { WorkflowEntrypoint, type WorkflowEvent, type WorkflowStep } from "cloudflare:workers";

import type { Verdict } from "../ingestion/dedupe";

export interface ArticleParams {
  sourceId: string;
  url: string;
  urlHash: string;
  title: string;
  publishedAt: number | null;
  imageUrl: string | null;
}

const RETRY = { retries: { limit: 3, delay: "30 seconds", backoff: "exponential" }, timeout: "2 minutes" } as const;

export class ProcessArticle extends WorkflowEntrypoint<Env, ArticleParams> {
  override async run(event: WorkflowEvent<ArticleParams>, step: WorkflowStep) {
    const article = event.payload;

    const pass1 = await step.do("dedupe pass 1", async (): Promise<Verdict> => {
      // T12: compare with titles from the last 48 h using checkPass1.
      return "distinct";
    });
    if (pass1 === "duplicate") {
      await step.do("attach as extra source", RETRY, async () => {
        // T12: insert into post_sources for the matching post.
      });
      return { outcome: "merged" };
    }

    await step.do("extract text", RETRY, async () => {
      // T13: fetch article HTML and extract readable text IN MEMORY ONLY (never stored).
      return { chars: 0 };
    });

    await step.do("summarise with AI", RETRY, async () => {
      // T13/T14: buildSummarizePrompt → LLMClient.completeJson → validateSummary + looksHindi; record ai_jobs.
    });

    await step.do("image", RETRY, async () => {
      // T15: apply image policy; store WebP in R2 (env.MEDIA).
    });

    await step.do("store and publish", RETRY, async () => {
      // T16: insert post (status published | review), then bumpFeedVersion(env).
    });

    return { outcome: "processed", url: article.url };
  }
}
