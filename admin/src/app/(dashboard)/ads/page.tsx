import type { Metadata } from "next";
import { EmptyState, NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { AdRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Ads" };

/** GET /admin/v1/ads. Permission ads:manage. Schema AdOut. */

export default async function AdsPage() {
  const { data, error } = await loadOrLogin<AdRow[]>("/admin/v1/ads");
  const rows = data ?? [];
  return (
    <NewsroomShell
      title="Ads"
      description="Direct-sold campaigns. A sponsored card sits in every sixth feed slot; a footer sits under the article."
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState
          title="No campaigns yet."
          body="Seed loads Kineto Sports (sponsored card) and Railways XI (footer) as examples."
        />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Advertiser</TableHead>
                <TableHead>Format</TableHead>
                <TableHead>Title</TableHead>
                <TableHead>Live</TableHead>
                <TableHead>Window</TableHead>
                <TableHead>Daily cap</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="font-medium">{row.advertiser}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{row.format}</Badge>
                  </TableCell>
                  <TableCell>{row.title ?? "—"}</TableCell>
                  <TableCell>{row.is_active ? "on" : "off"}</TableCell>
                  <TableCell className="tabular-nums">
                    {formatWhen(row.start_at)} – {formatWhen(row.end_at)}
                  </TableCell>
                  <TableCell className="tabular-nums">{row.daily_cap ?? "—"}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </NewsroomShell>
  );
}
