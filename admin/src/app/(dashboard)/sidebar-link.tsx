"use client";

import type { LucideIcon } from "lucide-react";
import {
  BarChart3,
  Bell,
  CheckSquare,
  FileText,
  LayoutDashboard,
  Megaphone,
  Radio,
  Rss,
  Settings,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const NAV_ICONS: Record<string, LucideIcon> = {
  "/overview": LayoutDashboard,
  "/review": CheckSquare,
  "/posts": FileText,
  "/studio": Sparkles,
  "/nxtspot": Radio,
  "/sources": Rss,
  "/ads": Megaphone,
  "/push": Bell,
  "/analytics": BarChart3,
  "/settings": Settings,
  "/audit": ShieldCheck,
};

export function SidebarLink({
  href,
  label,
  badge,
}: {
  href: string;
  label: string;
  badge?: string;
}) {
  const pathname = usePathname();
  const active = pathname === href || (href !== "/overview" && pathname.startsWith(href));
  const Icon = NAV_ICONS[href];

  return (
    <Link
      href={href}
      aria-current={active ? "page" : undefined}
      className={cn(
        "group relative flex items-center gap-2.5 rounded-lg px-2.5 py-1.5 text-sm font-medium transition-all duration-150",
        active
          ? "bg-primary/10 text-primary font-semibold shadow-xs dark:bg-primary/20"
          : "text-muted-foreground hover:bg-muted/60 hover:text-foreground",
      )}
    >
      {active && (
        <span
          className="absolute left-0 top-1/2 -translate-y-1/2 h-4 w-1 rounded-r-full bg-primary"
          aria-hidden
        />
      )}
      {Icon && (
        <Icon
          className={cn(
            "h-4 w-4 shrink-0 transition-transform duration-150 group-hover:scale-105",
            active ? "text-primary" : "text-muted-foreground group-hover:text-foreground",
          )}
        />
      )}
      <span className="truncate">{label}</span>
      {badge && (
        <span className="ml-auto rounded-full bg-primary/10 px-1.5 py-0.5 text-[10px] font-semibold text-primary">
          {badge}
        </span>
      )}
    </Link>
  );
}
