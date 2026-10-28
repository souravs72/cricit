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
import type { SourceRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Sources" };

/** GET /admin/v1/sources. Permission sources:manage. Schema SourceOut. */

export default async function SourcesPage() {
  const { data, error } = await loadOrLogin<SourceRow[]>("/admin/v1/sources");
  const rows = data ?? [];
  return (
    <NewsroomShell
      title="Sources"
      description="Verified news sites and official YouTube channels. We fetch RSS or a listing page; we never store the article body."
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState
          title="No sources yet."
          body="The T01 list is in docs/sources.md. Seed loads ESPNcricinfo, BBC, TOI, BCCI, ICC, Nxtspot and BCCI YouTube."
        />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Adapter</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Trust</TableHead>
                <TableHead>Health</TableHead>
                <TableHead>Last fetch</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="font-medium">
                    {row.name}
                    {!row.is_active ? (
                      <span className="ml-2 text-xs text-muted-foreground">paused</span>
                    ) : null}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{row.adapter ?? row.type}</Badge>
                  </TableCell>
                  <TableCell>{row.default_category}</TableCell>
                  <TableCell>{row.trust_level}</TableCell>
                  <TableCell>
                    {row.consecutive_failures > 0 ? `${row.consecutive_failures} failures` : "ok"}
                  </TableCell>
                  <TableCell className="tabular-nums">{formatWhen(row.last_fetched_at)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </NewsroomShell>
  );
}
