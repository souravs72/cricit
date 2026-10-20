import type { Metadata } from "next";
import Link from "next/link";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = { title: "Overview" };

/**
 * T26 wires these to /admin/v1/stats/overview. Until then they show dashes, never fake numbers.
 * Presented as a scoreboard strip rather than stat cards: it is the subject's own vernacular.
 */
const SCOREBOARD = [
  { label: "Cards published today", value: "–" },
  { label: "Waiting for review", value: "–" },
  { label: "Readers today", value: "–" },
  { label: "AI cost today", value: "–" },
];

export default function OverviewPage() {
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

      <section
        aria-label="Today"
        className="mt-8 grid grid-cols-2 overflow-hidden rounded-xl border bg-card md:grid-cols-4"
      >
        {SCOREBOARD.map((s) => (
          <div key={s.label} className="border-seam p-5 [&:not(:last-child)]:md:border-r">
            <p className="font-heading text-5xl font-semibold tabular-nums leading-none">{s.value}</p>
            <p className="mt-2 text-sm text-muted-foreground">{s.label}</p>
          </div>
        ))}
      </section>

      <section className="mt-10 grid gap-6 lg:grid-cols-[2fr_1fr]">
        <div>
          <h2 className="text-2xl font-semibold">Review queue</h2>
          <div className="mt-3 rounded-xl border bg-card px-6 py-10 text-center">
            <p className="font-medium">No cards waiting.</p>
            <p className="mx-auto mt-1 max-w-md text-sm text-muted-foreground">
              Cards from sources set to “review”, possible duplicates and every Nxtspot draft land here before
              they reach readers.
            </p>
          </div>
        </div>
        <div>
          <h2 className="text-2xl font-semibold">Source health</h2>
          <div className="mt-3 rounded-xl border bg-card px-6 py-10 text-center">
            <p className="font-medium">No sources yet.</p>
            <p className="mt-1 text-sm text-muted-foreground">Add the verified sources from week 1.</p>
            <Button asChild variant="outline" className="mt-4">
              <Link href="/sources">Add a source</Link>
            </Button>
          </div>
        </div>
      </section>
    </main>
  );
}
