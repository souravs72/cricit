import type { Metadata } from "next";
import { BarChart3, Eye, Flame, Layers, TrendingUp, Users } from "lucide-react";
import { NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { Overview, PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Analytics & Views" };

export default async function AnalyticsPage() {
  const stats = await loadOrLogin<Overview>("/admin/v1/stats/overview");
  const posts = await loadOrLogin<PostRow[]>("/admin/v1/posts");
  const error = stats.error ?? posts.error;
  const rows = posts.data ?? [];

  const byKind = countBy(rows, (r) => r.kind);
  const byCategory = countBy(rows, (r) => r.category);
  const byStatus = countBy(rows, (r) => r.status);

  return (
    <NewsroomShell
      title="Analytics & Engagement"
      description="Card impression analytics and category distribution. Views are rolled up in real-time from mobile client sessions."
      badge={
        <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold text-primary">
          {rows.length} Stories Indexed
        </span>
      }
      error={error}
    >
      {/* Top Stat Counters */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4 mb-8">
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase font-medium">Stories Published</p>
          <p className="mt-2 text-3xl font-bold font-heading text-foreground">
            {stats.data?.cards_published_today ?? "—"}
          </p>
          <p className="mt-1 text-[11px] text-emerald-600 font-medium">Today&apos;s output</p>
        </div>

        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase font-medium">Active Readers</p>
          <p className="mt-2 text-3xl font-bold font-heading text-foreground">
            {stats.data?.readers_today ?? "—"}
          </p>
          <p className="mt-1 text-[11px] text-sky-600 font-medium">Mobile session impressions</p>
        </div>

        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase font-medium">Pending Triage</p>
          <p className="mt-2 text-3xl font-bold font-heading text-foreground">
            {stats.data?.waiting_for_review ?? "—"}
          </p>
          <p className="mt-1 text-[11px] text-amber-600 font-medium">In review queue</p>
        </div>

        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase font-medium">AI Compute Spend</p>
          <p className="mt-2 text-3xl font-bold font-heading text-foreground">
            {stats.data?.ai_cost_today ?? "₹0.00"}
          </p>
          <p className="mt-1 text-[11px] text-purple-600 font-medium">Today&apos;s LLM cost</p>
        </div>
      </div>

      {/* Distribution Bars */}
      <div className="grid gap-6 md:grid-cols-2 mb-8">
        {/* Category Breakdown */}
        <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-xs space-y-4">
          <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
            Distribution by Category
          </h2>
          <div className="space-y-3">
            {byCategory.map(([cat, count]) => {
              const pct = rows.length > 0 ? Math.round((count / rows.length) * 100) : 0;
              return (
                <div key={cat} className="space-y-1">
                  <div className="flex justify-between text-xs">
                    <span className="font-semibold uppercase tracking-wider text-foreground">{cat}</span>
                    <span className="font-mono text-muted-foreground">
                      {count} ({pct}%)
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-muted overflow-hidden">
                    <div
                      className="h-full rounded-full bg-primary transition-all duration-300"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Format Breakdown */}
        <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-xs space-y-4">
          <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
            Content Formats & Status
          </h2>
          <div className="space-y-3">
            {byKind.map(([kind, count]) => {
              const pct = rows.length > 0 ? Math.round((count / rows.length) * 100) : 0;
              return (
                <div key={kind} className="space-y-1">
                  <div className="flex justify-between text-xs">
                    <span className="font-semibold text-foreground uppercase tracking-wider">{kind}</span>
                    <span className="font-mono text-muted-foreground">
                      {count} ({pct}%)
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-muted overflow-hidden">
                    <div
                      className="h-full rounded-full bg-emerald-600 transition-all duration-300"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Recent Indexed Stories */}
      <div className="space-y-3">
        <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">Top Indexed Stories</h2>
        <div className="divide-y divide-border/60 rounded-2xl border border-border/70 bg-card shadow-xs">
          {rows.slice(0, 10).map((row) => (
            <div key={row.id} className="flex items-center justify-between p-4 text-xs">
              <div className="space-y-1 pr-4 min-w-0">
                <p className="font-semibold text-foreground text-sm truncate">{row.headline}</p>
                <div className="flex items-center gap-2 text-muted-foreground">
                  <span className="uppercase text-[10px] font-semibold text-primary">{row.category}</span>
                  <span>·</span>
                  <span>{formatWhen(row.published_at)}</span>
                  {row.author_credit && (
                    <>
                      <span>·</span>
                      <span>By {row.author_credit}</span>
                    </>
                  )}
                </div>
              </div>
              <Badge variant="outline" className="shrink-0 font-mono text-[10px]">
                {row.status}
              </Badge>
            </div>
          ))}
        </div>
      </div>
    </NewsroomShell>
  );
}

function countBy(rows: PostRow[], key: (row: PostRow) => string): [string, number][] {
  const map = new Map<string, number>();
  for (const row of rows) {
    const k = key(row) || "other";
    map.set(k, (map.get(k) ?? 0) + 1);
  }
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}
