"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

export function SidebarLink({ href, label }: { href: string; label: string }) {
  const active = usePathname().startsWith(href);
  return (
    <Link
      href={href}
      aria-current={active ? "page" : undefined}
      className={cn(
        "relative rounded-md px-3 py-2 text-[15px] text-sidebar-foreground/80 hover:bg-sidebar-accent hover:text-sidebar-foreground",
        active && "bg-sidebar-accent font-semibold text-sidebar-accent-foreground",
      )}
    >
      {active && <span className="absolute inset-y-1.5 left-0 w-1 rounded-full bg-outfield" aria-hidden />}
      {label}
    </Link>
  );
}
