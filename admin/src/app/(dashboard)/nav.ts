/** Sidebar items. `permission` mirrors backend app/core/permissions.py; the backend still enforces. */
export type NavItem = { href: string; label: string; permission: string };

export const NAV: NavItem[] = [
  { href: "/overview", label: "Overview", permission: "dashboard:view" },
  { href: "/review", label: "Review queue", permission: "posts:write" },
  { href: "/posts", label: "Posts", permission: "dashboard:view" },
  { href: "/studio", label: "AI studio", permission: "nxtspot:create" },
  { href: "/nxtspot", label: "Nxtspot", permission: "nxtspot:create" },
  { href: "/sources", label: "Sources", permission: "sources:manage" },
  { href: "/ads", label: "Ads", permission: "ads:manage" },
  { href: "/push", label: "Push", permission: "push:send" },
  { href: "/analytics", label: "Analytics", permission: "dashboard:view" },
  { href: "/settings", label: "Settings", permission: "settings:manage" },
  { href: "/audit", label: "Audit log", permission: "audit:view" },
];

export function visibleNav(permissions: readonly string[]): NavItem[] {
  return NAV.filter((item) => permissions.includes(item.permission));
}
