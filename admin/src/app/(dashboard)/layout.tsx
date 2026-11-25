import Link from "next/link";
import { redirect } from "next/navigation";
import { LogOut, Radio, Sparkles } from "lucide-react";
import { ApiError, apiFetch } from "@/lib/api/server";
import { NAV_GROUPS, visibleNav } from "./nav";
import { SidebarLink } from "./sidebar-link";

type Me = { id: string; permissions: string[] };

async function getMe(): Promise<Me> {
  try {
    return await apiFetch<Me>("/admin/v1/me");
  } catch (e) {
    if (e instanceof ApiError && e.status === 401) redirect("/login");
    throw e;
  }
}

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const me = await getMe();
  const visible = visibleNav(me.permissions);

  return (
    <div className="grid min-h-dvh md:grid-cols-[250px_1fr]">
      {/* Desktop Sidebar */}
      <aside className="hidden border-r border-border/70 bg-card/60 backdrop-blur-md md:flex md:flex-col md:justify-between">
        <div className="flex flex-col">
          {/* Brand header */}
          <div className="border-b border-border/60 p-5">
            <Link href="/overview" className="flex items-center gap-3 group">
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground shadow-xs transition-transform group-hover:scale-105">
                <span className="font-heading text-lg font-bold tracking-tight">C</span>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5">
                  <span className="font-heading text-xl font-bold tracking-tight text-foreground">
                    CRICIT
                  </span>
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-600 dark:text-emerald-400">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    LIVE
                  </span>
                </div>
                <span className="text-xs text-muted-foreground font-medium">Newsroom SaaS</span>
              </div>
            </Link>
          </div>

          {/* Navigation with Category Groups */}
          <nav aria-label="Main" className="flex flex-col gap-5 px-3 py-4">
            {NAV_GROUPS.map((group) => {
              const groupItems = visible.filter((item) => item.group === group.key);
              if (groupItems.length === 0) return null;
              return (
                <div key={group.key} className="space-y-1">
                  <p className="px-2 text-[11px] font-semibold tracking-wider text-muted-foreground/80 uppercase">
                    {group.label}
                  </p>
                  <div className="space-y-0.5">
                    {groupItems.map((item) => (
                      <SidebarLink key={item.href} href={item.href} label={item.label} badge={item.badge} />
                    ))}
                  </div>
                </div>
              );
            })}
          </nav>
        </div>

        {/* User Card & Sign Out */}
        <div className="border-t border-border/60 p-3">
          <div className="flex items-center justify-between rounded-lg bg-muted/40 p-2.5">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary text-xs font-bold">
                SA
              </div>
              <div className="min-w-0">
                <p className="truncate text-xs font-semibold text-foreground">Super Admin</p>
                <p className="truncate text-[11px] text-muted-foreground">owner@cricit.app</p>
              </div>
            </div>
            <form action="/api/auth/logout" method="post">
              <button
                type="submit"
                title="Sign out"
                className="flex h-7 w-7 items-center justify-center rounded-md text-muted-foreground hover:bg-destructive/10 hover:text-destructive transition-colors"
              >
                <LogOut className="h-3.5 w-3.5" />
              </button>
            </form>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="min-w-0 flex flex-col bg-background">
        {/* Subtle Top Mobile / Tablet Header */}
        <header className="sticky top-0 z-20 flex h-14 items-center justify-between border-b border-border/60 bg-background/80 px-4 backdrop-blur-md md:hidden">
          <Link href="/overview" className="flex items-center gap-2">
            <div className="flex h-7 w-7 items-center justify-center rounded-md bg-primary text-primary-foreground font-bold text-xs">
              C
            </div>
            <span className="font-heading font-bold text-foreground">CRICIT</span>
          </Link>
          <div className="flex items-center gap-2">
            <form action="/api/auth/logout" method="post">
              <button
                type="submit"
                className="rounded-md border border-border/70 px-2.5 py-1 text-xs text-muted-foreground hover:bg-muted"
              >
                Sign out
              </button>
            </form>
          </div>
        </header>

        {children}
      </div>
    </div>
  );
}
