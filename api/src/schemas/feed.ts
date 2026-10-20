import { z } from "zod";

import { ValidationFailed } from "../core/errors";

export const Tab = z.enum(["feed", "domestic", "international", "nxtspot"]);
export const Lang = z.enum(["en", "hi"]);
export type Tab = z.infer<typeof Tab>;
export type Lang = z.infer<typeof Lang>;

export const FeedQuery = z.object({
  tab: Tab.default("feed"),
  lang: Lang.default("en"),
  cursor: z.string().max(200).optional(),
});

export const SearchQuery = z.object({
  q: z.string().trim().min(2).max(80),
  lang: Lang.default("en"),
});

/** One shape for every card kind, so the app renders one widget per kind. */
export interface Card {
  id: string;
  kind: "read" | "video" | "nxtspot";
  category: string;
  headline: string;
  summary: string;
  image: string | null;
  video_id: string | null;
  source: { name: string } | null;
  url: string | null;
  tags: string[];
  published_at: string;
  share_url: string;
}

export interface AdSlot {
  kind: "ad";
  format: "admob_native" | "sponsored_card" | "full_page" | "footer";
}

export interface FeedPage {
  items: (Card | AdSlot)[];
  next_cursor: string | null;
}

/** Opaque keyset cursor over (published_at, id). */
export function encodeCursor(publishedAt: number, id: string): string {
  return btoa(JSON.stringify({ t: publishedAt, id }))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replace(/=+$/, "");
}

export function decodeCursor(cursor: string): { t: number; id: string } {
  try {
    const b64 = cursor.replaceAll("-", "+").replaceAll("_", "/");
    const data = JSON.parse(atob(b64 + "=".repeat((4 - (b64.length % 4)) % 4))) as { t: unknown; id: unknown };
    if (typeof data.t !== "number" || typeof data.id !== "string") throw new Error("shape");
    return { t: data.t, id: data.id };
  } catch {
    throw new ValidationFailed("Invalid cursor", "cursor");
  }
}
