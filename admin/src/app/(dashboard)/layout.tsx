import Link from "next/link";
import { redirect } from "next/navigation";
import { ApiError, apiFetch } from "@/lib/api/server";
import { visibleNav } from "./nav";
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
  return (
    <div className="grid min-h-dvh md:grid-cols-[232px_1fr]">
      <aside className="hidden border-r bg-sidebar md:flex md:flex-col">
        <Link href="/overview" className="px-6 pb-6 pt-7">
          <span className="font-heading text-3xl font-semibold leading-none text-outfield">CRICIT</span>
          <span className="block text-sm text-muted-foreground">Newsroom</span>
        </Link>
        <nav aria-label="Main" className="flex flex-1 flex-col gap-0.5 px-3">
          {visibleNav(me.permissions).map((item) => (
            <SidebarLink key={item.href} href={item.href} label={item.label} />
          ))}
        </nav>
        <form action="/api/auth/logout" method="post" className="border-t p-3">
          <button className="w-full rounded-md px-3 py-2 text-left text-sm text-muted-foreground hover:bg-sidebar-accent">
            Sign out
          </button>
        </form>
      </aside>
      <div className="min-w-0">{children}</div>
    </div>
  );
}
