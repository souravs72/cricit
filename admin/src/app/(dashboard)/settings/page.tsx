import type { Metadata } from "next";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";

export const metadata: Metadata = { title: "Settings" };

/** GET /admin/v1/me. Role matrix matches backend app/core/permissions.py. */

const ROLES = [
  { role: "owner", access: "Everything, including ads, settings and the audit log" },
  { role: "editor", access: "Dashboard, posts, review, Nxtspot, sources, push" },
  { role: "viewer", access: "Dashboard and posts, read-only" },
];

export default async function SettingsPage() {
  const me = await loadOrLogin<{ id: string; permissions: string[] }>("/admin/v1/me");
  return (
    <NewsroomShell
      title="Settings"
      description="How this newsroom is locked down. Changing JWT keys or Firebase still happens in .env, not here."
      error={me.error}
    >
      <section className="rounded-xl border bg-card p-5">
        <h2 className="text-lg font-semibold">This session</h2>
        <dl className="mt-3 grid gap-2 text-sm md:grid-cols-2">
          <div>
            <dt className="text-muted-foreground">Admin id</dt>
            <dd className="font-mono text-xs">{me.data?.id ?? "—"}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Idle timeout</dt>
            <dd>30 minutes, then sign in again</dd>
          </div>
          <div className="md:col-span-2">
            <dt className="text-muted-foreground">Permissions on this token</dt>
            <dd className="mt-1 flex flex-wrap gap-2">
              {(me.data?.permissions ?? []).map((p) => (
                <span key={p} className="rounded-md bg-muted px-2 py-0.5 font-mono text-xs">
                  {p}
                </span>
              ))}
            </dd>
          </div>
        </dl>
      </section>
      <section className="mt-6 rounded-xl border bg-card p-5">
        <h2 className="text-lg font-semibold">Roles</h2>
        <ul className="mt-3 space-y-2 text-sm">
          {ROLES.map((row) => (
            <li key={row.role}>
              <span className="font-medium capitalize">{row.role}</span>
              <span className="text-muted-foreground"> — {row.access}</span>
            </li>
          ))}
        </ul>
      </section>
    </NewsroomShell>
  );
}
