import type { Metadata } from "next";
import { Rss, Sparkles } from "lucide-react";
import { SourcesManager } from "@/components/newsroom/sources-manager";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { SourceRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Source Feeds & Polling" };

export default async function SourcesPage() {
  const { data, error } = await loadOrLogin<SourceRow[]>("/admin/v1/sources");
  const rows = data ?? [];

  return (
    <NewsroomShell
      title="Source Feeds & Polling Engine"
      description="Manage verified RSS feeds, sitemaps, and YouTube channels. The ingestion engine polls these endpoints autonomously."
      badge={
        <span className="rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
          {rows.length} Active Feeds
        </span>
      }
      error={error}
    >
      <SourcesManager rows={rows} />
    </NewsroomShell>
  );
}
