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
import type { NxtspotRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Nxtspot" };

/** GET /admin/v1/nxtspot. Permission nxtspot:create. Schema: NxtspotOut. */

export default async function NxtspotPage() {
  const { data, error } = await loadOrLogin<NxtspotRow[]>("/admin/v1/nxtspot");
  const rows = data ?? [];
  return (
    <NewsroomShell
      title="Nxtspot"
      description="Grassroots submissions from readers. An editor drafts the card; nothing goes live on its own."
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState
          title="No submissions yet."
          body="Seed includes Anjali Menon (Palakkad) and Rahul Kulkarni (Pune) as examples."
        />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Submitter</TableHead>
                <TableHead>Location</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Note</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="font-medium">{row.submitter_name}</TableCell>
                  <TableCell>{row.location ?? "—"}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{row.status}</Badge>
                  </TableCell>
                  <TableCell className="max-w-md whitespace-normal text-muted-foreground">
                    {row.raw_text}
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
