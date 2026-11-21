/** vitest. Callers: npm test. Module: sources-form. */

import { describe, expect, it } from "vitest";
import { publicHttpUrl, sourceCreatePayload } from "./sources-form";

describe("publicHttpUrl", () => {
  it("rejects localhost and private IPs", () => {
    expect(publicHttpUrl("http://127.0.0.1/rss.xml")).toBeNull();
    expect(publicHttpUrl("http://localhost/rss.xml")).toBeNull();
    expect(publicHttpUrl("http://10.0.0.8/feed")).toBeNull();
  });
  it("accepts a public RSS URL", () => {
    expect(publicHttpUrl("https://feeds.bbci.co.uk/sport/cricket/rss.xml")).toContain("bbci");
  });
});

describe("sourceCreatePayload", () => {
  it("builds an rss create body", () => {
    const body = sourceCreatePayload({
      name: "BBC Sport Cricket",
      adapter: "rss",
      feed_url: "https://feeds.bbci.co.uk/sport/cricket/rss.xml",
      default_category: "international",
      trust_level: "review",
    });
    expect(body.adapter).toBe("rss");
    expect(body.adapter_config).toEqual({
      feed_url: "https://feeds.bbci.co.uk/sport/cricket/rss.xml",
    });
  });

  it("builds an html create body", () => {
    const body = sourceCreatePayload({
      name: "BCCI",
      adapter: "html",
      feed_url: "https://www.bcci.tv/news",
      default_category: "domestic",
      trust_level: "review",
    });
    expect(body.adapter).toBe("html");
    expect(body.adapter_config).toEqual({ listing_url: "https://www.bcci.tv/news" });
  });

  it("builds a sitemap create body", () => {
    const body = sourceCreatePayload({
      name: "BCCI sitemap",
      adapter: "sitemap",
      feed_url: "https://www.bcci.tv/news-sitemap.xml",
      default_category: "domestic",
      trust_level: "review",
    });
    expect(body.adapter).toBe("sitemap");
    expect(body.adapter_config).toEqual({
      sitemap_url: "https://www.bcci.tv/news-sitemap.xml",
    });
  });

  it("builds a youtube create body", () => {
    const body = sourceCreatePayload({
      name: "Cricbuzz Shorts",
      adapter: "youtube",
      feed_url: "@cricbuzz",
      default_category: "domestic",
      trust_level: "auto",
    });
    expect(body.adapter).toBe("youtube");
    expect(body.type).toBe("youtube_channel");
    expect(body.adapter_config).toEqual({ handle: "@cricbuzz" });
  });

  it("builds a twitter/x create body", () => {
    const body = sourceCreatePayload({
      name: "BCCI on X",
      adapter: "x",
      feed_url: "https://x.com/BCCI",
      default_category: "domestic",
      trust_level: "auto",
    });
    expect(body.adapter).toBe("x");
    expect(body.type).toBe("x");
    expect(body.adapter_config).toEqual({ handle: "BCCI" });
  });
});
