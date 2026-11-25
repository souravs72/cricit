import type { Metadata } from "next";
import { DollarSign, Megaphone, MousePointerClick, TrendingUp } from "lucide-react";
import { EmptyState, NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { AdRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Ad Campaigns" };

export default async function AdsPage() {
  const { data, error } = await loadOrLogin<AdRow[]>("/admin/v1/ads");
  const rows = data ?? [];

  const totalImpressions = rows.reduce((acc, r) => acc + (r.impressions_today ?? 0), 0);
  const totalClicks = rows.reduce((acc, r) => acc + (r.clicks_today ?? 0), 0);
  const avgCtr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : "0.00";

  return (
    <NewsroomShell
      title="Sponsored Campaigns & Monetization"
      description="Direct-sold sponsor placements. Sponsored cards appear cleanly every 6th card in the feed; footer sponsors render at the article base."
      badge={
        <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold text-primary">
          {rows.length} campaigns
        </span>
      }
      error={error}
    >
      {/* Metrics Row */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 mb-6">
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase tracking-wider font-medium">
            Active Sponsors
          </p>
          <p className="mt-2 text-2xl font-bold font-heading text-foreground">
            {rows.filter((r) => r.is_active).length}
          </p>
        </div>
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase tracking-wider font-medium">
            Impressions Today
          </p>
          <p className="mt-2 text-2xl font-bold font-heading text-foreground">
            {totalImpressions.toLocaleString()}
          </p>
        </div>
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase tracking-wider font-medium">Clicks Today</p>
          <p className="mt-2 text-2xl font-bold font-heading text-foreground">
            {totalClicks.toLocaleString()}
          </p>
        </div>
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <p className="text-xs text-muted-foreground uppercase tracking-wider font-medium">Average CTR</p>
          <p className="mt-2 text-2xl font-bold font-heading text-primary">{avgCtr}%</p>
        </div>
      </div>

      {rows.length === 0 ? (
        <EmptyState
          title="No campaigns running."
          body="Seed loads Kineto Sports (sponsored card) and Railways XI (footer) as live examples."
        />
      ) : (
        <div className="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs">
          <Table>
            <TableHeader className="bg-muted/30">
              <TableRow>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">
                  Advertiser & Campaign
                </TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">Format</TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">Status</TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">
                  Flight Window
                </TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider text-right">
                  Daily Cap
                </TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider text-right">
                  Performance
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id} className="hover:bg-muted/30">
                  <TableCell className="py-3.5">
                    <div>
                      <p className="font-semibold text-foreground text-sm">{row.advertiser}</p>
                      <p className="text-xs text-muted-foreground">{row.title ?? "General placement"}</p>
                    </div>
                  </TableCell>

                  <TableCell className="py-3.5">
                    <Badge variant="outline" className="font-mono text-[10px]">
                      {row.format}
                    </Badge>
                  </TableCell>

                  <TableCell className="py-3.5">
                    <span
                      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold ${
                        row.is_active
                          ? "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
                          : "bg-muted text-muted-foreground"
                      }`}
                    >
                      <span
                        className={`h-1.5 w-1.5 rounded-full ${
                          row.is_active ? "bg-emerald-500" : "bg-muted-foreground"
                        }`}
                      />
                      {row.is_active ? "Live" : "Paused"}
                    </span>
                  </TableCell>

                  <TableCell className="py-3.5 text-xs font-mono tabular-nums text-muted-foreground">
                    {formatWhen(row.start_at)} – {formatWhen(row.end_at)}
                  </TableCell>

                  <TableCell className="py-3.5 text-right text-xs font-mono tabular-nums text-muted-foreground">
                    {row.daily_cap ? `${row.daily_cap.toLocaleString()} imp` : "Unlimited"}
                  </TableCell>

                  <TableCell className="py-3.5 text-right">
                    <div className="text-xs font-mono">
                      <span className="font-semibold text-foreground">{row.impressions_today ?? 0}</span>{" "}
                      <span className="text-muted-foreground">views</span> ·{" "}
                      <span className="font-semibold text-primary">{row.clicks_today ?? 0}</span>{" "}
                      <span className="text-muted-foreground">clicks</span>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </NewsroomShell>
  );
}
