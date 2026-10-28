import type { Metadata } from "next";
import { EmptyState, NewsroomShell } from "@/components/newsroom/shell";
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
import type { AuditRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Audit log" };

/** GET /admin/v1/audit. Permission audit:view. Schema AuditOut. */

export default async function AuditPage() {
  const { data, error } = await loadOrLogin<AuditRow[]>("/admin/v1/audit");
  const rows = data ?? [];
  return (
    <NewsroomShell
      title="Audit log"
      description="Every sign-in, failed attempt and seed run. Writes from publish/reject will land here too."
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState title="Nothing recorded yet." body="Logging in and running make seed both write rows." />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>When</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Entity</TableHead>
                <TableHead>Note</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="tabular-nums">{formatWhen(row.ts)}</TableCell>
                  <TableCell className="font-mono text-xs">{row.action}</TableCell>
                  <TableCell>{row.entity}</TableCell>
                  <TableCell className="text-muted-foreground">{row.note ?? "—"}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </NewsroomShell>
  );
}
