import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { formatWhen } from "@/lib/format";
import type { PostRow } from "@/lib/newsroom";
import { EmptyState } from "./shell";

/** Renders GET /admin/v1/posts and /review rows. Importers: posts, review, studio, overview. */

export function PostsTable({
  rows,
  emptyTitle,
  emptyBody,
}: {
  rows: PostRow[];
  emptyTitle: string;
  emptyBody: string;
}) {
  if (rows.length === 0) return <EmptyState title={emptyTitle} body={emptyBody} />;
  return (
    <div className="overflow-hidden rounded-xl border bg-card">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Headline</TableHead>
            <TableHead>Kind</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Category</TableHead>
            <TableHead>Credit</TableHead>
            <TableHead>Published</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={row.id}>
              <TableCell className="max-w-sm whitespace-normal font-medium">{row.headline}</TableCell>
              <TableCell>
                <Badge variant="outline">{row.kind}</Badge>
              </TableCell>
              <TableCell>{row.status}</TableCell>
              <TableCell>{row.category}</TableCell>
              <TableCell className="text-muted-foreground">{row.author_credit ?? "—"}</TableCell>
              <TableCell className="tabular-nums">{formatWhen(row.published_at)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
