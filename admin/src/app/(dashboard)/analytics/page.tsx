import type { Metadata } from "next";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { Overview, PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Analytics" };

/** GET /admin/v1/stats/overview + /posts. Readers/cost stay 0 until T26 counters. */

export default async function AnalyticsPage() {
  const stats = await loadOrLogin<Overview>("/admin/v1/stats/overview");
  const posts = await loadOrLogin<PostRow[]>("/admin/v1/posts");
  const error = stats.error ?? posts.error;
  const rows = posts.data ?? [];
  const byKind = countBy(rows, (r) => r.kind);
  const byCategory = countBy(rows, (r) => r.category);
  return (
    <NewsroomShell
      title="Analytics"
      description="Counts from the database. Reader totals stay at zero until Redis counters land in T26 — we do not invent traffic."
      error={error}
    >
      <dl className="grid grid-cols-2 overflow-hidden rounded-xl border bg-card md:grid-cols-4">
        <Stat label="Published today" value={stats.data?.cards_published_today ?? "—"} />
        <Stat label="Waiting for review" value={stats.data?.waiting_for_review ?? "—"} />
        <Stat label="Readers today" value={stats.data?.readers_today ?? "—"} />
        <Stat label="AI cost today" value={stats.data?.ai_cost_today ?? "—"} />
      </dl>
      <div className="mt-8 grid gap-6 md:grid-cols-2">
        <Breakdown title="By kind" items={byKind} />
        <Breakdown title="By category" items={byCategory} />
      </div>
    </NewsroomShell>
  );
}

function countBy(rows: PostRow[], key: (row: PostRow) => string): [string, number][] {
  const map = new Map<string, number>();
  for (const row of rows) {
    map.set(key(row), (map.get(key(row)) ?? 0) + 1);
  }
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="border-seam p-5 [&:not(:last-child)]:md:border-r">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className="mt-2 font-heading text-4xl font-semibold tabular-nums">{value}</dd>
    </div>
  );
}

function Breakdown({ title, items }: { title: string; items: [string, number][] }) {
  return (
    <section className="rounded-xl border bg-card p-5">
      <h2 className="text-lg font-semibold">{title}</h2>
      <ul className="mt-3 space-y-2">
        {items.length === 0 ? (
          <li className="text-sm text-muted-foreground">No posts to count yet.</li>
        ) : (
          items.map(([label, n]) => (
            <li key={label} className="flex justify-between text-sm">
              <span>{label}</span>
              <span className="tabular-nums text-muted-foreground">{n}</span>
            </li>
          ))
        )}
      </ul>
    </section>
  );
}
