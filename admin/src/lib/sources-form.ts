/** Client-side source form checks.

Callers: sources-manager.tsx, sources-form.test.ts.
API: POST /admin/v1/sources. Schema: SourceCreate (name, adapter, feed_url).
User: "Check what is tobe built now into this - build it"
*/

const PRIVATE = /^(localhost|127\.|10\.|192\.168\.|169\.254\.|0\.0\.0\.0|\[::1\])/i;

export function publicHttpUrl(value: string): string | null {
  try {
    const url = new URL(value);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    if (PRIVATE.test(url.hostname) || url.hostname.endsWith(".local")) return null;
    return url.toString();
  } catch {
    return null;
  }
}

export type SourceForm = {
  name: string;
  adapter: "rss" | "html" | "sitemap" | "youtube";
  feed_url: string;
  default_category: "international" | "domestic" | "grassroots";
  trust_level: "auto" | "review";
};

export function sourceCreatePayload(form: SourceForm) {
  const url = publicHttpUrl(form.feed_url);
  if (!form.name.trim() || form.name.trim().length < 2) {
    throw new Error("Name needs at least two characters.");
  }
  if (form.adapter === "rss") {
    if (!url) throw new Error("Feed URL must be a public http(s) address.");
    return {
      name: form.name.trim(),
      type: "news" as const,
      adapter: "rss" as const,
      adapter_config: { feed_url: url },
      default_category: form.default_category,
      trust_level: form.trust_level,
    };
  }
  if (form.adapter === "html") {
    if (!url) throw new Error("Listing URL must be a public http(s) address.");
    return {
      name: form.name.trim(),
      type: "news" as const,
      adapter: "html" as const,
      adapter_config: { listing_url: url },
      default_category: form.default_category,
      trust_level: form.trust_level,
    };
  }
  if (form.adapter === "sitemap") {
    if (!url) throw new Error("Sitemap URL must be a public http(s) address.");
    return {
      name: form.name.trim(),
      type: "news" as const,
      adapter: "sitemap" as const,
      adapter_config: { sitemap_url: url },
      default_category: form.default_category,
      trust_level: form.trust_level,
    };
  }
  throw new Error("YouTube sources are added from seed until T17.");
}
