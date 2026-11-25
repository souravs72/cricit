import type { Metadata } from "next";
import Link from "next/link";
import {
  Activity,
  ArrowRight,
  BarChart3,
  Check,
  CheckCircle2,
  Clock,
  ExternalLink,
  Flame,
  PlusCircle,
  Radio,
  Rss,
  Sparkles,
  Users,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { Overview, PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Overview" };

export default async function OverviewPage() {
  const { data, error } = await loadOrLogin<Overview>("/admin/v1/stats/overview");

  const cardsToday = data?.cards_published_today ?? 0;
  const inReview = data?.waiting_for_review ?? 0;
  const readers = data?.readers_today ?? 0;
  const aiCost = data?.ai_cost_today ?? "₹0.00";
  const pendingReviews = (data?.review ?? []).slice(0, 4);
  const sources = (data?.sources ?? []).slice(0, 5);

  return (
    <main className="flex-1 p-6 md:p-8 max-w-7xl space-y-6">
      {/* Top Welcome & Quick Actions Bar */}
      <div className="flex flex-col gap-4 border-b border-border/60 pb-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold tracking-tight text-foreground md:text-3xl">
              Editorial Command Center
            </h1>
            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2 py-0.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Live Ingestion
            </span>
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            Cricket news intelligence: real-time synthesis, autonomous polling, and triage.
          </p>
        </div>

        {/* Action Shortcuts */}
        <div className="flex flex-wrap items-center gap-2">
          <Button asChild size="sm" className="gap-1.5 text-xs">
            <Link href="/studio">
              <Sparkles className="h-3.5 w-3.5" />
              Create Story (AI Copilot)
            </Link>
          </Button>
          <Button asChild variant="outline" size="sm" className="gap-1.5 text-xs">
            <Link href="/review">
              <CheckCircle2 className="h-3.5 w-3.5 text-amber-600" />
              Review Queue ({inReview})
            </Link>
          </Button>
        </div>
      </div>

      {error ? (
        <div className="rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-xs text-destructive">
          <p className="font-semibold">Backend connection notice</p>
          <p className="mt-0.5">{error}</p>
        </div>
      ) : null}

      {/* Modern Compact KPI Scoreboard */}
      <section aria-label="KPI Metrics" className="grid grid-cols-2 gap-3.5 lg:grid-cols-4">
        {/* Metric 1 */}
        <div className="rounded-xl border border-border/70 bg-card p-4 shadow-2xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Stories Today</span>
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600">
              <Flame className="h-3.5 w-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="font-heading text-2xl font-bold tabular-nums text-foreground">{cardsToday}</span>
            <span className="text-[10px] font-medium text-emerald-600">Autonomous</span>
          </div>
          <p className="mt-0.5 text-[11px] text-muted-foreground truncate">Synthesized & published</p>
        </div>

        {/* Metric 2 */}
        <div className="rounded-xl border border-border/70 bg-card p-4 shadow-2xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Needs Editorial</span>
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-amber-500/10 text-amber-600">
              <Clock className="h-3.5 w-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="font-heading text-2xl font-bold tabular-nums text-foreground">{inReview}</span>
            {inReview > 0 && (
              <span className="text-[10px] font-medium text-amber-600 animate-pulse">Pending triage</span>
            )}
          </div>
          <p className="mt-0.5 text-[11px] text-muted-foreground truncate">Awaiting review approval</p>
        </div>

        {/* Metric 3 */}
        <div className="rounded-xl border border-border/70 bg-card p-4 shadow-2xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-[11px] font-semibold uppercase tracking-wider">Readers Today</span>
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-sky-500/10 text-sky-600">
              <Users className="h-3.5 w-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="font-heading text-2xl font-bold tabular-nums text-foreground">{readers}</span>
            <span className="text-[10px] font-medium text-sky-600">Card views</span>
          </div>
          <p className="mt-0.5 text-[11px] text-muted-foreground truncate">Mobile deck impressions</p>
        </div>

        {/* Metric 4 */}
        <div className="rounded-xl border border-border/70 bg-card p-4 shadow-2xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-[11px] font-semibold uppercase tracking-wider">AI Compute Cost</span>
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-purple-500/10 text-purple-600">
              <Sparkles className="h-3.5 w-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="font-heading text-2xl font-bold tabular-nums text-foreground">{aiCost}</span>
            <span className="text-[10px] font-medium text-purple-600">Cost optimized</span>
          </div>
          <p className="mt-0.5 text-[11px] text-muted-foreground truncate">Claude 3.5 / OpenAI tokens</p>
        </div>
      </section>

      {/* Main 2-Column Compact Layout */}
      <section className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
        {/* Left Column: Top Pending Review Cards */}
        <div className="rounded-xl border border-border/70 bg-card p-5 shadow-2xs space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
                Pending Editorial Sign-off
              </h2>
              {inReview > 0 && (
                <span className="rounded-full bg-amber-500/10 px-2 py-0.5 text-[11px] font-bold text-amber-700 dark:text-amber-400">
                  {inReview}
                </span>
              )}
            </div>
            <Link
              href="/review"
              className="inline-flex items-center gap-1 text-xs font-semibold text-primary hover:underline"
            >
              Open Review Queue ({inReview}) <ArrowRight className="h-3 w-3" />
            </Link>
          </div>

          {pendingReviews.length === 0 ? (
            <div className="py-8 text-center text-xs text-muted-foreground">
              <CheckCircle2 className="h-6 w-6 mx-auto mb-2 text-emerald-600" />
              <p className="font-medium text-foreground">All caught up!</p>
              <p className="mt-0.5">No stories currently waiting for review.</p>
            </div>
          ) : (
            <div className="divide-y divide-border/60">
              {pendingReviews.map((item) => (
                <div key={item.id} className="py-3 first:pt-0 last:pb-0 space-y-1.5">
                  <div className="flex items-start justify-between gap-3">
                    <p className="text-sm font-semibold text-foreground leading-snug line-clamp-1 hover:text-primary transition-colors">
                      {item.headline}
                    </p>
                    <span className="shrink-0 rounded bg-muted/80 px-1.5 py-0.5 text-[10px] font-mono uppercase text-muted-foreground">
                      {item.category}
                    </span>
                  </div>
                  {item.summary && (
                    <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                      {item.summary}
                    </p>
                  )}
                  <div className="flex items-center justify-between pt-1 text-[11px]">
                    <span className="text-muted-foreground font-mono">
                      {item.author_credit ? `By ${item.author_credit}` : formatWhen(item.published_at)}
                    </span>
                    <Link
                      href={`/review?highlight=${item.id}`}
                      className="inline-flex items-center gap-1 font-semibold text-primary hover:underline"
                    >
                      Triage card <ArrowRight className="h-2.5 w-2.5" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Right Column: Source Feeds & System Health */}
        <div className="space-y-4">
          {/* Source Feed Status */}
          <div className="rounded-xl border border-border/70 bg-card p-5 shadow-2xs space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
                Source Feed Pulse
              </h2>
              <Link href="/sources" className="text-xs font-semibold text-primary hover:underline">
                Manage feeds →
              </Link>
            </div>

            <ul className="divide-y divide-border/60">
              {sources.map((src) => {
                const isHealthy = src.consecutive_failures === 0;
                return (
                  <li key={src.id} className="flex items-center justify-between py-2.5 text-xs">
                    <div className="flex items-center gap-2 min-w-0">
                      <span
                        className={`h-2 w-2 shrink-0 rounded-full ${
                          isHealthy ? "bg-emerald-500" : "bg-destructive animate-ping"
                        }`}
                      />
                      <span className="font-medium text-foreground truncate">{src.name}</span>
                    </div>
                    <span
                      className={`text-[10px] font-mono px-2 py-0.5 rounded-full ${
                        isHealthy
                          ? "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 font-semibold"
                          : "bg-destructive/10 text-destructive font-semibold"
                      }`}
                    >
                      {isHealthy ? "healthy" : `${src.consecutive_failures} fails`}
                    </span>
                  </li>
                );
              })}
            </ul>
          </div>

          {/* Quick Engine Status Card */}
          <div className="rounded-xl border border-border/70 bg-muted/20 p-4 space-y-2 text-xs">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-foreground">Autonomous Engine</span>
              <span className="rounded-full bg-emerald-500/10 px-2 py-0.5 text-[10px] font-mono font-bold text-emerald-600">
                ACTIVE
              </span>
            </div>
            <p className="text-[11px] text-muted-foreground leading-relaxed">
              Polling RSS feeds & YouTube every 15m. Articles undergo automatic in-memory readability
              extraction, deduplication, and bilingual synthesis.
            </p>
            <div className="pt-2 border-t border-border/40 flex items-center justify-between text-[10px] text-muted-foreground">
              <span>FastAPI Backend · Postgres 16</span>
              <Link href="/settings" className="font-semibold text-primary hover:underline">
                Configure AI & Keys →
              </Link>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
