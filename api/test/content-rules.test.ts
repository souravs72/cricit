import { describe, expect, it } from "vitest";

import { looksHindi, validateSummary } from "../src/ai/validators";
import { ROLE_PERMISSIONS, Permission } from "../src/core/permissions";
import { canonicalUrl, checkPass1, checkPass2, normaliseTitle, tokenSetRatio } from "../src/ingestion/dedupe";
import { parseFeed } from "../src/ingestion/rss";
import { decodeCursor, encodeCursor } from "../src/schemas/feed";

const NOW = Date.UTC(2026, 9, 20, 12);
const H = 3600_000;

describe("dedupe", () => {
  it("matches rapidfuzz token_set_ratio on the measured examples", () => {
    const s = (a: string, b: string) => Math.round(tokenSetRatio(normaliseTitle(a), normaliseTitle(b)));
    expect(s("Kohli hits 50th ODI hundred", "Virat Kohli reaches 50 ODI centuries")).toBe(57);
    expect(s("Kohli hits 50th ODI hundred", "Kohli out for duck in 3rd ODI")).toBe(50);
    expect(s("India beat Australia in Perth Test", "India lose to Australia in Perth Test")).toBe(92);
    expect(s("Bumrah ruled out of Perth Test with back injury", "Bumrah injury: pacer misses Perth Test")).toBe(79);
  });

  it("canonicalises URLs (tracking params, www, amp)", () => {
    expect(canonicalUrl("http://www.espncricinfo.com/story/abc/amp?utm_source=x&id=7")).toBe(
      canonicalUrl("https://espncricinfo.com/story/abc?id=7"),
    );
  });

  it("merges near-identical titles", () => {
    const old = { title: "India beat Australia by 6 wickets in Perth", publishedAt: NOW };
    expect(checkPass1({ title: "India beat Australia by 6 wickets in Perth!", publishedAt: NOW + 2 * H }, [old])).toBe(
      "duplicate",
    );
  });

  it("never auto-merges opposite results or different numbers", () => {
    const old = { title: "India beat Australia in Perth Test", publishedAt: NOW };
    expect(checkPass1({ title: "India lose to Australia in Perth Test", publishedAt: NOW + H }, [old])).toBe(
      "possible",
    );
    const odi = { title: "India beat Australia by 6 wickets in 3rd ODI", publishedAt: NOW };
    expect(checkPass1({ title: "India beat Australia by 4 wickets in 4th ODI", publishedAt: NOW + H }, [odi])).not.toBe(
      "duplicate",
    );
  });

  it("ignores stories outside the window", () => {
    const old = { title: "India beat Australia by 6 wickets in Perth", publishedAt: NOW - 72 * H };
    expect(checkPass1({ title: "India beat Australia by 6 wickets in Perth", publishedAt: NOW }, [old])).toBe(
      "distinct",
    );
  });

  it("flags reworded stories with shared tags for review (pass 2)", () => {
    const tags = new Set(["virat kohli", "india"]);
    const old = { title: "Kohli hits 50th ODI hundred", publishedAt: NOW, tags };
    expect(checkPass2({ title: "Virat Kohli reaches 50 ODI centuries", publishedAt: NOW + H, tags }, [old])).toBe(
      "possible",
    );
    expect(checkPass2({ title: "Virat Kohli reaches 50 ODI centuries", publishedAt: NOW + 9 * H, tags }, [old])).toBe(
      "distinct",
    );
    expect(checkPass2({ title: "Kohli out for a duck in 3rd ODI", publishedAt: NOW + H, tags }, [old])).toBe(
      "distinct",
    );
  });
});

describe("AI summary validation", () => {
  const source = "India scored 287 for 5. Gill made 104.";
  const filler = Array(55).fill("word").join(" ");

  it("flags numbers that are not in the source", () => {
    const r = validateSummary({ summary: `${filler} India scored 300.`, headline: "India win", sourceText: source });
    expect(r.ok).toBe(false);
    expect(r.reasons.join()).toContain("300");
  });

  it("passes a faithful summary", () => {
    const r = validateSummary({
      summary: `${filler} India scored 287 and Gill made 104.`,
      headline: "Gill 104 powers India",
      sourceText: source,
    });
    expect(r).toEqual({ ok: true, reasons: [] });
  });

  it("detects Hindi text", () => {
    expect(looksHindi("भारत ने ऑस्ट्रेलिया को छह विकेट से हराया")).toBe(true);
    expect(looksHindi("India beat Australia")).toBe(false);
  });
});

describe("RSS parsing", () => {
  it("reads RSS 2.0 items with media images and skips incomplete ones", () => {
    const xml = `<?xml version="1.0"?><rss xmlns:media="http://search.yahoo.com/mrss/"><channel>
      <item><title>Gill 104 powers India</title><link>https://example.com/a</link>
        <pubDate>Tue, 20 Oct 2026 10:00:00 GMT</pubDate><media:content url="https://img.example.com/a.jpg"/></item>
      <item><title>No link</title></item></channel></rss>`;
    const items = parseFeed(xml);
    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({ url: "https://example.com/a", imageUrl: "https://img.example.com/a.jpg" });
    expect(items[0]!.publishedAt).toBe(Date.UTC(2026, 9, 20, 10));
  });

  it("reads Atom entries", () => {
    const xml = `<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>Atom story</title>
      <link rel="alternate" href="https://example.com/b"/><updated>2026-10-20T10:00:00Z</updated></entry></feed>`;
    expect(parseFeed(xml)[0]).toMatchObject({ title: "Atom story", url: "https://example.com/b" });
  });
});

describe("cursors and roles", () => {
  it("round-trips cursors and rejects garbage", () => {
    expect(decodeCursor(encodeCursor(NOW, "0192abcd"))).toEqual({ t: NOW, id: "0192abcd" });
    expect(() => decodeCursor("not-a-cursor")).toThrow("Invalid cursor");
  });

  it("matches the permission matrix in the plan", () => {
    expect(ROLE_PERMISSIONS.editor.has(Permission.POSTS_PUBLISH)).toBe(true);
    expect(ROLE_PERMISSIONS.editor.has(Permission.ADS_MANAGE)).toBe(false);
    expect(ROLE_PERMISSIONS.editor.has(Permission.ADMINS_MANAGE)).toBe(false);
    expect([...ROLE_PERMISSIONS.viewer]).toEqual([Permission.DASHBOARD_VIEW]);
    expect(ROLE_PERMISSIONS.owner.size).toBe(Object.keys(Permission).length);
  });
});
