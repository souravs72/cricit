"use client";

/** List, pause, create, test-fetch. Callers: admin/src/app/(dashboard)/sources/page.tsx.
 * API: POST/PATCH /admin/v1/sources, POST /admin/v1/sources/{id}/test.
 * Schema: SourceRow, TestFetchOut. User: "Check what is tobe built now into this - build it"
 */

import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { formatWhen } from "@/lib/format";
import type { SourceRow } from "@/lib/newsroom";
import { proxyJson } from "@/lib/proxy";
import { sourceCreatePayload } from "@/lib/sources-form";
import { EmptyState } from "./shell";

type Preview = { title: string; url: string };

export function SourcesManager({ rows }: { rows: SourceRow[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [preview, setPreview] = useState<{ name: string; items: Preview[] } | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function pause(row: SourceRow, is_active: boolean) {
    setBusy(row.id);
    try {
      await proxyJson(`admin/v1/sources/${row.id}`, {
        method: "PATCH",
        body: JSON.stringify({ is_active }),
      });
      toast.success(is_active ? "Resumed" : "Paused");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Could not update source.");
    } finally {
      setBusy(null);
    }
  }

  async function testFetch(row: SourceRow) {
    setBusy(`test-${row.id}`);
    try {
      const out = await proxyJson<{ items: Preview[] }>(`admin/v1/sources/${row.id}/test`, {
        method: "POST",
        body: "{}",
      });
      setPreview({ name: row.name, items: out.items ?? [] });
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Test fetch failed.");
    } finally {
      setBusy(null);
    }
  }

  async function onCreate(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const form = new FormData(e.currentTarget);
    try {
      const body = sourceCreatePayload({
        name: String(form.get("name") ?? ""),
        adapter: (form.get("adapter") as "rss" | "html") ?? "rss",
        feed_url: String(form.get("feed_url") ?? ""),
        default_category:
          (form.get("default_category") as "international" | "domestic" | "grassroots") ??
          "international",
        trust_level: (form.get("trust_level") as "auto" | "review") ?? "review",
      });
      setBusy("create");
      await proxyJson("admin/v1/sources", { method: "POST", body: JSON.stringify(body) });
      toast.success("Source added");
      e.currentTarget.reset();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not add source.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-8">
      <form onSubmit={onCreate} className="grid gap-4 rounded-xl border bg-card p-4 md:grid-cols-2">
        <div className="space-y-2 md:col-span-2">
          <p className="font-medium">Add a source</p>
          <p className="text-sm text-muted-foreground">
            RSS only fetches headlines and a short teaser. We never store the article body.
          </p>
        </div>
        <div className="space-y-2">
          <Label htmlFor="name">Name</Label>
          <Input id="name" name="name" required minLength={2} placeholder="BBC Sport Cricket" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="adapter">Adapter</Label>
          <select
            id="adapter"
            name="adapter"
            defaultValue="rss"
            className="h-8 w-full rounded-lg border border-input bg-transparent px-2.5 text-sm"
          >
            <option value="rss">RSS</option>
            <option value="html">HTML listing</option>
          </select>
        </div>
        <div className="space-y-2 md:col-span-2">
          <Label htmlFor="feed_url">Feed or listing URL</Label>
          <Input
            id="feed_url"
            name="feed_url"
            type="url"
            required
            placeholder="https://feeds.bbci.co.uk/sport/cricket/rss.xml"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="default_category">Category</Label>
          <select
            id="default_category"
            name="default_category"
            defaultValue="international"
            className="h-8 w-full rounded-lg border border-input bg-transparent px-2.5 text-sm"
          >
            <option value="international">international</option>
            <option value="domestic">domestic</option>
            <option value="grassroots">grassroots</option>
          </select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="trust_level">Trust</Label>
          <select
            id="trust_level"
            name="trust_level"
            defaultValue="review"
            className="h-8 w-full rounded-lg border border-input bg-transparent px-2.5 text-sm"
          >
            <option value="review">review</option>
            <option value="auto">auto</option>
          </select>
        </div>
        {error ? (
          <p role="alert" className="text-sm text-destructive md:col-span-2">
            {error}
          </p>
        ) : null}
        <div className="md:col-span-2">
          <Button type="submit" disabled={busy === "create"}>
            Save source
          </Button>
        </div>
      </form>

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
                <TableHead>Trust</TableHead>
                <TableHead>Health</TableHead>
                <TableHead>Last fetch</TableHead>
                <TableHead>Actions</TableHead>
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
                    {row.feed_url ? (
                      <p className="mt-1 max-w-xs truncate text-xs text-muted-foreground">
                        {row.feed_url}
                      </p>
                    ) : null}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{row.adapter ?? row.type}</Badge>
                  </TableCell>
                  <TableCell>{row.trust_level}</TableCell>
                  <TableCell>
                    {row.consecutive_failures > 0
                      ? `${row.consecutive_failures} failures`
                      : "ok"}
                    {row.last_error ? (
                      <p className="max-w-xs truncate text-xs text-destructive">{row.last_error}</p>
                    ) : null}
                  </TableCell>
                  <TableCell className="tabular-nums">{formatWhen(row.last_fetched_at)}</TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={busy === row.id}
                        onClick={() => pause(row, !row.is_active)}
                      >
                        {row.is_active ? "Pause" : "Resume"}
                      </Button>
                      <Button
                        size="sm"
                        variant="secondary"
                        disabled={busy === `test-${row.id}` || row.adapter !== "rss"}
                        onClick={() => testFetch(row)}
                      >
                        Test fetch
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {preview ? (
        <div className="rounded-xl border bg-card p-4">
          <p className="font-medium">Preview · {preview.name}</p>
          {preview.items.length === 0 ? (
            <p className="mt-2 text-sm text-muted-foreground">No items returned.</p>
          ) : (
            <ul className="mt-3 space-y-2 text-sm">
              {preview.items.map((item) => (
                <li key={item.url}>
                  <a href={item.url} className="underline" rel="noreferrer" target="_blank">
                    {item.title}
                  </a>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}
    </div>
  );
}
