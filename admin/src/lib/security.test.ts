import { describe, expect, it } from "vitest";
import { visibleNav } from "@/app/(dashboard)/nav";
import { isAllowedProxyPath, isPublicPath, isSameOrigin } from "./security";

describe("isSameOrigin", () => {
  it("allows safe methods without an Origin header", () => {
    expect(isSameOrigin("GET", null, "admin.cricit.app")).toBe(true);
  });
  it("blocks cross-site and missing-origin writes", () => {
    expect(isSameOrigin("POST", "https://evil.example", "admin.cricit.app")).toBe(false);
    expect(isSameOrigin("POST", null, "admin.cricit.app")).toBe(false);
    expect(isSameOrigin("DELETE", "not a url", "admin.cricit.app")).toBe(false);
  });
  it("allows same-origin writes", () => {
    expect(isSameOrigin("PATCH", "https://admin.cricit.app", "admin.cricit.app")).toBe(true);
  });
});

describe("isAllowedProxyPath", () => {
  it("only reaches the admin API", () => {
    expect(isAllowedProxyPath("admin/v1/posts")).toBe(true);
    expect(isAllowedProxyPath("v1/feed")).toBe(false);
    expect(isAllowedProxyPath("admin/v1/../../internal")).toBe(false);
  });
});

describe("isPublicPath", () => {
  it("keeps the dashboard private", () => {
    expect(isPublicPath("/login")).toBe(true);
    expect(isPublicPath("/overview")).toBe(false);
    expect(isPublicPath("/loginx")).toBe(false);
  });
});

describe("visibleNav", () => {
  it("hides owner-only pages from editors", () => {
    const editor = [
      "dashboard:view",
      "posts:write",
      "posts:publish",
      "nxtspot:create",
      "push:send",
      "sources:manage",
    ];
    const labels = visibleNav(editor).map((i) => i.label);
    expect(labels).toContain("Review queue");
    expect(labels).not.toContain("Ads");
    expect(labels).not.toContain("Audit log");
  });
});
