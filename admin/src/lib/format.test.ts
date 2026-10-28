import { describe, expect, it } from "vitest";
import { formatWhen } from "./format";

describe("formatWhen", () => {
  it("returns an em dash for missing dates", () => {
    expect(formatWhen(null)).toBe("—");
    expect(formatWhen(undefined)).toBe("—");
    expect(formatWhen("not-a-date")).toBe("—");
  });

  it("formats an ISO timestamp in India time", () => {
    const text = formatWhen("2026-10-28T06:30:00.000Z");
    expect(text).toMatch(/2026/);
    expect(text).toMatch(/12:00/);
  });
});
