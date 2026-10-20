/**
 * Provider-agnostic LLM interface. T13 adds the concrete adapter (routed through
 * Cloudflare AI Gateway for caching, retries, cost logs and a provider fallback).
 */
import { SUMMARIZE_V1 } from "./prompts";

export interface LLMResult<T> {
  data: T;
  model: string;
  inputTokens: number;
  outputTokens: number;
}

export interface LLMClient {
  completeJson<T>(args: {
    system: string;
    user: string;
    schema: Record<string, unknown>;
    maxTokens?: number;
  }): Promise<LLMResult<T>>;
}

export interface SummaryOutput {
  headline: string;
  summary: string;
  category: "domestic" | "international" | "grassroots";
  tags: string[];
  headline_hi: string;
  summary_hi: string;
  relevance: number;
}

export const SUMMARY_SCHEMA = {
  type: "object",
  required: ["headline", "summary", "category", "tags", "headline_hi", "summary_hi", "relevance"],
  properties: {
    headline: { type: "string", maxLength: 80 },
    summary: { type: "string" },
    category: { enum: ["domestic", "international", "grassroots"] },
    tags: { type: "array", items: { type: "string" }, maxItems: 8 },
    headline_hi: { type: "string" },
    summary_hi: { type: "string" },
    relevance: { type: "number", minimum: 0, maximum: 1 },
  },
} as const;

export function buildSummarizePrompt(args: { title: string; sourceName: string; articleText: string }) {
  return {
    version: SUMMARIZE_V1.version,
    user: SUMMARIZE_V1.template
      .replace("{title}", args.title)
      .replace("{source_name}", args.sourceName)
      .replace("{article_text}", args.articleText.slice(0, 12_000)),
  };
}
