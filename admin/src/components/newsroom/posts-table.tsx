import type { ReactNode } from "react";
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

function safeHttpUrl(value: string | null | undefined): string | null {
  if (!value) return null;
  try {
    const url = new URL(value);
    if (url.protocol === "http:" || url.protocol === "https:") return value;
  } catch {
    return null;
  }
  return null;
}

export function PostsTable({
  rows,
  emptyTitle,
  emptyBody,
  actions,
  highlightId,
}: {
  rows: PostRow[];
  emptyTitle: string;
  emptyBody: string;
  actions?: (row: PostRow) => ReactNode;
  highlightId?: string;
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
            <TableHead>Link</TableHead>
            <TableHead>Published</TableHead>
            {actions ? <TableHead>Actions</TableHead> : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={row.id} data-active={row.id === highlightId ? "true" : undefined}>
              <TableCell className="max-w-sm whitespace-normal font-medium">
                {row.headline}
                {row.summary ? (
                  <p className="mt-1 text-sm font-normal text-muted-foreground">{row.summary}</p>
                ) : null}
              </TableCell>
              <TableCell>
                <Badge variant="outline">{row.kind}</Badge>
              </TableCell>
              <TableCell>{row.status}</TableCell>
              <TableCell>{row.category}</TableCell>
              <TableCell className="text-muted-foreground">{row.author_credit ?? "—"}</TableCell>
              <TableCell>
                {safeHttpUrl(row.original_url) ? (
                  <a
                    href={safeHttpUrl(row.original_url) ?? undefined}
                    className="text-sm underline"
                    rel="noreferrer"
                    target="_blank"
                  >
                    Original
                  </a>
                ) : (
                  "—"
                )}
              </TableCell>
              <TableCell className="tabular-nums">{formatWhen(row.published_at)}</TableCell>
              {actions ? <TableCell>{actions(row)}</TableCell> : null}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
