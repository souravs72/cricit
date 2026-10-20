/** RSS/Atom adapter with conditional GET, so an unchanged feed costs one 304. */
import { XMLParser } from "fast-xml-parser";

export interface RawItem {
  url: string;
  title: string;
  publishedAt: number | null;
  imageUrl: string | null;
}

export interface FetchResult {
  items: RawItem[];
  etag: string | null;
  lastModified: string | null;
  notModified: boolean;
}

const USER_AGENT = "CRICITBot/1.0 (+https://cricit.app/bot)";
const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: "@_", textNodeName: "#text" });

const asArray = <T>(v: T | T[] | undefined): T[] => (v === undefined ? [] : Array.isArray(v) ? v : [v]);
const text = (v: unknown): string =>
  typeof v === "string"
    ? v
    : typeof v === "object" && v && "#text" in v
      ? String((v as Record<string, unknown>)["#text"])
      : "";
const time = (v: unknown): number | null => {
  const t = Date.parse(text(v));
  return Number.isFinite(t) ? t : null;
};

/** Parse RSS 2.0 or Atom XML into items. Exported for fixture tests. */
export function parseFeed(xml: string): RawItem[] {
  const doc = parser.parse(xml) as Record<string, any>;
  const rssItems = asArray(doc.rss?.channel?.item);
  if (rssItems.length) {
    return rssItems
      .map((it: Record<string, any>) => ({
        url: text(it.link).trim(),
        title: text(it.title).trim(),
        publishedAt: time(it.pubDate ?? it["dc:date"]),
        imageUrl: it["media:content"]?.["@_url"] ?? it["media:thumbnail"]?.["@_url"] ?? it.enclosure?.["@_url"] ?? null,
      }))
      .filter((i) => i.url && i.title);
  }
  return asArray(doc.feed?.entry)
    .map((it: Record<string, any>) => {
      const links = asArray(it.link) as Record<string, string>[];
      const href = links.find((l) => !l["@_rel"] || l["@_rel"] === "alternate")?.["@_href"] ?? "";
      return {
        url: href.trim(),
        title: text(it.title).trim(),
        publishedAt: time(it.published ?? it.updated),
        imageUrl: null,
      };
    })
    .filter((i) => i.url && i.title);
}

export async function fetchRss(
  feedUrl: string,
  prev: { etag: string | null; lastModified: string | null },
): Promise<FetchResult> {
  const headers: Record<string, string> = {
    "User-Agent": USER_AGENT,
    Accept: "application/rss+xml, application/atom+xml, application/xml",
  };
  if (prev.etag) headers["If-None-Match"] = prev.etag;
  if (prev.lastModified) headers["If-Modified-Since"] = prev.lastModified;
  const res = await fetch(feedUrl, { headers, signal: AbortSignal.timeout(15_000) });
  if (res.status === 304) return { items: [], etag: prev.etag, lastModified: prev.lastModified, notModified: true };
  if (!res.ok) throw new Error(`Feed returned HTTP ${res.status}`);
  return {
    items: parseFeed(await res.text()),
    etag: res.headers.get("ETag"),
    lastModified: res.headers.get("Last-Modified"),
    notModified: false,
  };
}
