/** vitest. Callers: npm test. Module: sources-form. User: "Check what is tobe built now into this - build it" */

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
});
