import type { Metadata } from "next";
import Link from "next/link";
import { PostsTable } from "@/components/newsroom/posts-table";
import { Button } from "@/components/ui/button";
import { loadOrLogin } from "@/lib/api/server";
import type { Overview } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Overview" };

/** GET /admin/v1/stats/overview. Schema OverviewStats. Never invent reader counts. */

export default async function OverviewPage() {
  const { data, error } = await loadOrLogin<Overview>("/admin/v1/stats/overview");
  const scoreboard = [
    { label: "Cards published today", value: data?.cards_published_today ?? "—" },
    { label: "Waiting for review", value: data?.waiting_for_review ?? "—" },
    { label: "Readers today", value: data?.readers_today ?? "—" },
    { label: "AI cost today", value: data?.ai_cost_today ?? "—" },
  ];
  return (
    <main className="px-6 py-8 md:px-10">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-4xl font-semibold">Overview</h1>
          <p className="mt-1 text-muted-foreground">What is live in the app and what needs you.</p>
        </div>
        <Button asChild>
          <Link href="/review">Open review queue</Link>
        </Button>
      </header>

      {error ? (
        <p role="alert" className="mt-8 text-sm text-destructive">
          {error}
        </p>
      ) : null}

      <section
        aria-label="Today"
        className="mt-8 grid grid-cols-2 overflow-hidden rounded-xl border bg-card md:grid-cols-4"
      >
        {scoreboard.map((s) => (
          <div key={s.label} className="border-seam p-5 [&:not(:last-child)]:md:border-r">
            <p className="font-heading text-5xl font-semibold tabular-nums leading-none">{s.value}</p>
            <p className="mt-2 text-sm text-muted-foreground">{s.label}</p>
          </div>
        ))}
      </section>

      <section className="mt-10 grid gap-6 lg:grid-cols-[2fr_1fr]">
        <div>
          <h2 className="text-2xl font-semibold">Review queue</h2>
          <div className="mt-3">
            <PostsTable
              rows={data?.review ?? []}
              emptyTitle="No cards waiting."
              emptyBody="Cards from sources set to review, possible duplicates and every Nxtspot draft land here before they reach readers."
            />
          </div>
        </div>
        <div>
          <h2 className="text-2xl font-semibold">Source health</h2>
          <div className="mt-3 rounded-xl border bg-card">
            {(data?.sources ?? []).length === 0 ? (
              <div className="px-6 py-10 text-center">
                <p className="font-medium">No sources yet.</p>
                <p className="mt-1 text-sm text-muted-foreground">Add the verified sources from week 1.</p>
                <Button asChild variant="outline" className="mt-4">
                  <Link href="/sources">Add a source</Link>
                </Button>
              </div>
            ) : (
              <ul className="divide-y">
                {(data?.sources ?? []).slice(0, 8).map((src) => (
                  <li key={src.id} className="flex items-center justify-between px-5 py-3 text-sm">
                    <span className="font-medium">{src.name}</span>
                    <span className="text-muted-foreground">
                      {src.consecutive_failures > 0 ? `${src.consecutive_failures} failures` : "ok"}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </section>
    </main>
  );
}
