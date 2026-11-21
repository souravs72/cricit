export type NavItem = {
  href: string;
  label: string;
  permission: string;
  badge?: string;
  group: "editorial" | "growth" | "system";
};

export const NAV_GROUPS = [
  { key: "editorial", label: "Editorial & Newsroom" },
  { key: "growth", label: "Network & Distribution" },
  { key: "system", label: "Observability & Control" },
] as const;

export const NAV: NavItem[] = [
  {
    href: "/overview",
    label: "Overview",
    permission: "dashboard:view",
    group: "editorial",
  },
  {
    href: "/review",
    label: "Review queue",
    permission: "posts:write",
    group: "editorial",
  },
  {
    href: "/posts",
    label: "Posts & Stories",
    permission: "dashboard:view",
    group: "editorial",
  },
  {
    href: "/studio",
    label: "Create Story (AI Copilot)",
    permission: "nxtspot:create",
    group: "editorial",
  },
  {
    href: "/nxtspot",
    label: "Nxtspot Grassroots",
    permission: "nxtspot:create",
    group: "growth",
  },
  {
    href: "/sources",
    label: "Source Feeds",
    permission: "sources:manage",
    group: "growth",
  },
  {
    href: "/ads",
    label: "Ad Campaigns",
    permission: "ads:manage",
    group: "growth",
  },
  {
    href: "/push",
    label: "Push Broadcasts",
    permission: "push:send",
    group: "growth",
  },
  {
    href: "/analytics",
    label: "Analytics & Views",
    permission: "dashboard:view",
    group: "system",
  },
  {
    href: "/settings",
    label: "Settings & AI",
    permission: "settings:manage",
    group: "system",
  },
  {
    href: "/audit",
    label: "Security Audit",
    permission: "audit:view",
    group: "system",
  },
];

export function visibleNav(permissions: readonly string[]): NavItem[] {
  return NAV.filter((item) => permissions.includes(item.permission));
}
