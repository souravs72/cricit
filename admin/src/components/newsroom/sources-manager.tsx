"use client";

/** Sources and Triggers Control Panel.
 * Callers: admin/src/app/(dashboard)/sources/page.tsx.
 * API: POST/PATCH /admin/v1/sources, POST /admin/v1/sources/{id}/test.
 * Schema: SourceRow, TestFetchOut.
 */

import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";
import {
  Radio,
  Globe,
  CheckCircle2,
  AlertCircle,
  Play,
  Pause,
  ExternalLink,
  PlusCircle,
  RefreshCw,
  Zap,
} from "lucide-react";
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

type Preview = { title: string; url: string; published_at?: string };

function YoutubeIcon({ className = "size-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
    </svg>
  );
}

function TwitterIcon({ className = "size-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

const PRESETS = [
  {
    name: "Cricbuzz Shorts",
    adapter: "youtube" as const,
    feed_url: "@cricbuzz",
    category: "domestic" as const,
    trust: "auto" as const,
    icon: YoutubeIcon,
    desc: "YouTube Shorts",
  },
  {
    name: "BCCI Shorts",
    adapter: "youtube" as const,
    feed_url: "@BCCI",
    category: "domestic" as const,
    trust: "auto" as const,
    icon: YoutubeIcon,
    desc: "BCCI Official",
  },
  {
    name: "ICC Shorts",
    adapter: "youtube" as const,
    feed_url: "@ICC",
    category: "international" as const,
    trust: "auto" as const,
    icon: YoutubeIcon,
    desc: "ICC Global",
  },
  {
    name: "BCCI on X",
    adapter: "x" as const,
    feed_url: "BCCI",
    category: "domestic" as const,
    trust: "auto" as const,
    icon: TwitterIcon,
    desc: "Team India official X",
  },
  {
    name: "Cricbuzz News",
    adapter: "html" as const,
    feed_url: "https://www.cricbuzz.com/cricket-news",
    category: "domestic" as const,
    trust: "review" as const,
    icon: Globe,
    desc: "Web News Headlines",
  },
  {
    name: "ESPNcricinfo Feed",
    adapter: "rss" as const,
    feed_url: "https://www.espncricinfo.com/rss/content/story/feeds/0.xml",
    category: "international" as const,
    trust: "auto" as const,
    icon: Radio,
    desc: "Global RSS Feed",
  },
];

export function SourcesManager({ rows }: { rows: SourceRow[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [preview, setPreview] = useState<{ name: string; items: Preview[] } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedAdapter, setSelectedAdapter] = useState<string>("rss");
  const [filterType, setFilterType] = useState<string>("all");

  async function pause(row: SourceRow, is_active: boolean) {
    setBusy(row.id);
    try {
      await proxyJson(`admin/v1/sources/${row.id}`, {
        method: "PATCH",
        body: JSON.stringify({ is_active }),
      });
      toast.success(is_active ? `Resumed ${row.name}` : `Paused ${row.name}`);
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
      toast.success(`Fetched ${out.items?.length ?? 0} items from ${row.name}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Test fetch failed.");
    } finally {
      setBusy(null);
    }
  }

  async function ingestNow(row: SourceRow) {
    setBusy(`ingest-${row.id}`);
    try {
      const out = await proxyJson<{
        ok: boolean;
        fetched: number;
        inserted: number;
        merged: number;
        errors: number;
      }>(`admin/v1/sources/${row.id}/ingest`, {
        method: "POST",
        body: "{}",
      });
      toast.success(
        `Ingested ${row.name}: ${out.inserted} new cards, ${out.merged} merged, ${out.errors} errors.`
      );
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Ingest failed.");
    } finally {
      setBusy(null);
    }
  }

  async function runAllIngestion() {
    setBusy("run-all");
    try {
      const out = await proxyJson<{
        ok: boolean;
        sources_polled: number;
        total_inserted: number;
        total_merged: number;
        total_errors: number;
      }>("admin/v1/ingest/run", {
        method: "POST",
        body: "{}",
      });
      toast.success(
        `Ingestion Complete: Polled ${out.sources_polled} sources → +${out.total_inserted} new cards (+${out.total_merged} merged).`
      );
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Run all ingestion failed.");
    } finally {
      setBusy(null);
    }
  }

  async function applyPreset(p: typeof PRESETS[number]) {
    setError(null);
    try {
      const body = sourceCreatePayload({
        name: p.name,
        adapter: p.adapter,
        feed_url: p.feed_url,
        default_category: p.category,
        trust_level: p.trust,
      });
      setBusy("preset-" + p.name);
      await proxyJson("admin/v1/sources", { method: "POST", body: JSON.stringify(body) });
      toast.success(`Added preset: ${p.name}`);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not add source preset.");
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
        adapter: (form.get("adapter") as "rss" | "html" | "sitemap" | "youtube" | "x") ?? "rss",
        feed_url: String(form.get("feed_url") ?? ""),
        default_category:
          (form.get("default_category") as "international" | "domestic" | "grassroots") ??
          "international",
        trust_level: (form.get("trust_level") as "auto" | "review") ?? "review",
      });
      setBusy("create");
      await proxyJson("admin/v1/sources", { method: "POST", body: JSON.stringify(body) });
      toast.success("Source added successfully");
      e.currentTarget.reset();
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not add source.");
    } finally {
      setBusy(null);
    }
  }

  const activeCount = rows.filter((r) => r.is_active).length;
  const youtubeCount = rows.filter((r) => r.adapter === "youtube" || r.type.includes("youtube")).length;
  const xCount = rows.filter((r) => r.adapter === "x" || r.type === "x").length;
  const newsCount = rows.length - youtubeCount - xCount;

  const filteredRows = rows.filter((row) => {
    if (filterType === "youtube") return row.adapter === "youtube" || row.type.includes("youtube");
    if (filterType === "x") return row.adapter === "x" || row.type === "x";
    if (filterType === "news") return row.adapter !== "youtube" && row.adapter !== "x" && row.type !== "x";
    return true;
  });

  return (
    <div className="space-y-8">
      {/* Top metrics summary */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <div className="rounded-xl border bg-card p-4">
          <p className="text-sm font-medium text-muted-foreground">Active Triggers</p>
          <p className="mt-1 font-heading text-3xl font-semibold text-outfield">{activeCount} / {rows.length}</p>
        </div>
        <div className="rounded-xl border bg-card p-4">
          <p className="text-sm font-medium text-muted-foreground">YouTube Channels</p>
          <div className="mt-1 flex items-center gap-2">
            <YoutubeIcon className="size-5 text-red-600" />
            <p className="font-heading text-3xl font-semibold">{youtubeCount}</p>
          </div>
        </div>
        <div className="rounded-xl border bg-card p-4">
          <p className="text-sm font-medium text-muted-foreground">X / Twitter Feeds</p>
          <div className="mt-1 flex items-center gap-2">
            <TwitterIcon className="size-5 text-sky-500" />
            <p className="font-heading text-3xl font-semibold">{xCount}</p>
          </div>
        </div>
        <div className="rounded-xl border bg-card p-4">
          <p className="text-sm font-medium text-muted-foreground">News & Web Feeds</p>
          <div className="mt-1 flex items-center gap-2">
            <Globe className="size-5 text-emerald-600" />
            <p className="font-heading text-3xl font-semibold">{newsCount}</p>
          </div>
        </div>
      </div>

      {/* Preset Quick Ingestion Cards */}
      <div className="rounded-xl border bg-card p-5">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-medium">Quick-Add Official Cricket Triggers</h3>
            <p className="text-xs text-muted-foreground">
              Official channels specified in brief: Cricbuzz, BCCI, ICC, Twitter/X handles.
            </p>
          </div>
        </div>
        <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {PRESETS.map((p) => {
            const Icon = p.icon;
            const alreadyAdded = rows.some((r) => r.name.toLowerCase() === p.name.toLowerCase());
            return (
              <div
                key={p.name}
                className="flex items-center justify-between rounded-lg border bg-background/50 p-3 hover:border-outfield/50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="rounded-md bg-muted p-2">
                    <Icon className="size-4" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold">{p.name}</p>
                    <p className="text-xs text-muted-foreground">{p.desc}</p>
                  </div>
                </div>
                <Button
                  size="sm"
                  variant={alreadyAdded ? "ghost" : "outline"}
                  disabled={alreadyAdded || busy === "preset-" + p.name}
                  onClick={() => applyPreset(p)}
                >
                  {alreadyAdded ? (
                    <span className="flex items-center gap-1 text-xs text-muted-foreground">
                      <CheckCircle2 className="size-3 text-emerald-600" /> Added
                    </span>
                  ) : (
                    <span className="flex items-center gap-1 text-xs">
                      <PlusCircle className="size-3" /> Add
                    </span>
                  )}
                </Button>
              </div>
            );
          })}
        </div>
      </div>

      {/* Add Custom Source Form */}
      <form onSubmit={onCreate} className="grid gap-4 rounded-xl border bg-card p-5 md:grid-cols-2">
        <div className="space-y-1 md:col-span-2">
          <p className="font-medium">Add New Source or Social Media Trigger</p>
          <p className="text-sm text-muted-foreground">
            Configure RSS feeds, HTML web listing scrapers, YouTube Shorts channels, or X/Twitter handles.
          </p>
        </div>
        <div className="space-y-2">
          <Label htmlFor="name">Source Name</Label>
          <Input id="name" name="name" required minLength={2} placeholder="e.g. Harsha Bhogle Shorts, Fox Cricket" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="adapter">Adapter Type</Label>
          <select
            id="adapter"
            name="adapter"
            value={selectedAdapter}
            onChange={(e) => setSelectedAdapter(e.target.value)}
            className="h-9 w-full rounded-lg border border-input bg-transparent px-3 text-sm focus:outline-none focus:ring-1 focus:ring-outfield"
          >
            <option value="rss">RSS / Atom Feed (ESPN, BBC, TOI, NDTV)</option>
            <option value="youtube">YouTube Channel / Shorts (@handle or URL)</option>
            <option value="x">X / Twitter Handle (@handle or URL)</option>
            <option value="html">HTML News Listing (BCCI, ICC, Cricbuzz)</option>
            <option value="sitemap">News Sitemap (XML)</option>
          </select>
        </div>
        <div className="space-y-2 md:col-span-2">
          <Label htmlFor="feed_url">
            {selectedAdapter === "youtube"
              ? "YouTube Channel Handle or URL (e.g. @cricbuzz or https://youtube.com/@BCCI/shorts)"
              : selectedAdapter === "x"
              ? "X / Twitter Handle or Profile URL (e.g. @BCCI or https://x.com/ICC)"
              : "Feed / Listing URL"}
          </Label>
          <Input
            id="feed_url"
            name="feed_url"
            required
            placeholder={
              selectedAdapter === "youtube"
                ? "@cricbuzz"
                : selectedAdapter === "x"
                ? "BCCI"
                : "https://www.espncricinfo.com/rss/content/story/feeds/0.xml"
            }
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="default_category">Category</Label>
          <select
            id="default_category"
            name="default_category"
            defaultValue="international"
            className="h-9 w-full rounded-lg border border-input bg-transparent px-3 text-sm focus:outline-none focus:ring-1 focus:ring-outfield"
          >
            <option value="international">International</option>
            <option value="domestic">Domestic (Indian Cricket)</option>
            <option value="grassroots">Nxtspot / Grassroots</option>
          </select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="trust_level">Publish Workflow</Label>
          <select
            id="trust_level"
            name="trust_level"
            defaultValue="review"
            className="h-9 w-full rounded-lg border border-input bg-transparent px-3 text-sm focus:outline-none focus:ring-1 focus:ring-outfield"
          >
            <option value="review">Review First (editor signs off)</option>
            <option value="auto">Auto-Publish (direct to readers)</option>
          </select>
        </div>
        {error ? (
          <p role="alert" className="text-sm font-medium text-destructive md:col-span-2">
            {error}
          </p>
        ) : null}
        <div className="md:col-span-2">
          <Button type="submit" disabled={busy === "create"} className="bg-outfield hover:bg-outfield/90 text-white">
            <PlusCircle className="mr-2 size-4" /> Save Trigger
          </Button>
        </div>
      </form>

      {/* Sources List & Filter Tabs */}
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex rounded-lg border bg-muted p-1 text-xs">
            <button
              onClick={() => setFilterType("all")}
              className={`rounded-md px-3 py-1.5 font-medium transition-colors ${
                filterType === "all" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
              }`}
            >
              All Sources ({rows.length})
            </button>
            <button
              onClick={() => setFilterType("youtube")}
              className={`rounded-md px-3 py-1.5 font-medium transition-colors ${
                filterType === "youtube" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
              }`}
            >
              YouTube ({youtubeCount})
            </button>
            <button
              onClick={() => setFilterType("x")}
              className={`rounded-md px-3 py-1.5 font-medium transition-colors ${
                filterType === "x" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
              }`}
            >
              X / Twitter ({xCount})
            </button>
            <button
              onClick={() => setFilterType("news")}
              className={`rounded-md px-3 py-1.5 font-medium transition-colors ${
                filterType === "news" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
              }`}
            >
              News & RSS ({newsCount})
            </button>
          </div>

          <Button
            size="sm"
            className="h-8 gap-1.5 bg-emerald-600 text-white hover:bg-emerald-700 text-xs shadow-sm font-semibold"
            disabled={busy === "run-all"}
            onClick={runAllIngestion}
          >
            <Zap className={`size-3.5 ${busy === "run-all" ? "animate-spin" : ""}`} />
            {busy === "run-all" ? "Ingesting All Sources..." : "Run All Ingestion"}
          </Button>
        </div>

        {filteredRows.length === 0 ? (
          <EmptyState
            title="No triggers match this filter."
            body="Use the preset buttons or the form above to add news sources and short video channels."
          />
        ) : (
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Trigger / Channel</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Trust</TableHead>
                  <TableHead>Status & Health</TableHead>
                  <TableHead>Last Fetch</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredRows.map((row) => {
                  const isYt = row.adapter === "youtube" || row.type.includes("youtube");
                  const isX = row.adapter === "x" || row.type === "x";
                  return (
                    <TableRow key={row.id}>
                      <TableCell className="font-medium">
                        <div className="flex items-center gap-2">
                          {isYt ? (
                            <YoutubeIcon className="size-4 text-red-500 shrink-0" />
                          ) : isX ? (
                            <TwitterIcon className="size-4 text-sky-500 shrink-0" />
                          ) : (
                            <Globe className="size-4 text-emerald-600 shrink-0" />
                          )}
                          <div>
                            <span>{row.name}</span>
                            {!row.is_active && (
                              <Badge variant="secondary" className="ml-2 text-[10px]">
                                Paused
                              </Badge>
                            )}
                            {row.feed_url && (
                              <p className="mt-0.5 max-w-xs truncate text-xs text-muted-foreground">
                                {row.feed_url}
                              </p>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline" className="capitalize text-xs">
                          {row.adapter ?? row.type}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <span className="capitalize text-xs text-muted-foreground">
                          {row.default_category}
                        </span>
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant={row.trust_level === "auto" ? "default" : "secondary"}
                          className={`text-xs ${
                            row.trust_level === "auto" ? "bg-emerald-600/15 text-emerald-700 hover:bg-emerald-600/20" : ""
                          }`}
                        >
                          {row.trust_level === "auto" ? "Auto-post" : "Review"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {row.consecutive_failures > 0 ? (
                          <div className="flex items-center gap-1.5 text-xs text-destructive">
                            <AlertCircle className="size-3.5" />
                            <span>{row.consecutive_failures} failures</span>
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 text-xs text-emerald-600">
                            <CheckCircle2 className="size-3.5" />
                            <span>Healthy</span>
                          </div>
                        )}
                        {row.last_error && (
                          <p className="max-w-xs truncate text-[11px] text-destructive/80">{row.last_error}</p>
                        )}
                      </TableCell>
                      <TableCell className="tabular-nums text-xs text-muted-foreground">
                        {formatWhen(row.last_fetched_at)}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            className="h-8 px-2.5 text-xs"
                            disabled={busy === row.id}
                            onClick={() => pause(row, !row.is_active)}
                          >
                            {row.is_active ? (
                              <>
                                <Pause className="mr-1 size-3 text-muted-foreground" /> Pause
                              </>
                            ) : (
                              <>
                                <Play className="mr-1 size-3 text-emerald-600" /> Resume
                              </>
                            )}
                          </Button>
                          <Button
                            size="sm"
                            variant="secondary"
                            className="h-8 px-2.5 text-xs"
                            disabled={busy === `test-${row.id}`}
                            onClick={() => testFetch(row)}
                          >
                            <RefreshCw className={`mr-1 size-3 ${busy === `test-${row.id}` ? "animate-spin" : ""}`} />
                            Test Fetch
                          </Button>
                          <Button
                            size="sm"
                            className="h-8 px-2.5 text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-medium"
                            disabled={busy === `ingest-${row.id}`}
                            onClick={() => ingestNow(row)}
                            title="Fetch new content and generate AI card summaries immediately"
                          >
                            <Zap className={`mr-1 size-3 ${busy === `ingest-${row.id}` ? "animate-spin" : ""}`} />
                            Ingest Now
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {/* Live Preview Modal / Drawer */}
      {preview && (
        <div className="rounded-xl border bg-card p-5 shadow-sm">
          <div className="flex items-center justify-between border-b pb-3">
            <div>
              <p className="font-semibold text-foreground">Live Fetch Preview · {preview.name}</p>
              <p className="text-xs text-muted-foreground">
                Showing top parsed cards/videos directly from this trigger.
              </p>
            </div>
            <Button size="sm" variant="ghost" onClick={() => setPreview(null)}>
              Dismiss
            </Button>
          </div>
          {preview.items.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              No items returned. If this is a YouTube channel or X handle, check that the handle is valid.
            </p>
          ) : (
            <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {preview.items.slice(0, 6).map((item, idx) => (
                <div key={item.url + idx} className="flex flex-col justify-between rounded-lg border bg-background p-3">
                  <div>
                    <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                      {item.url.includes("youtube.com") ? "YouTube Short" : item.url.includes("x.com") ? "X Tweet" : "News Article"}
                    </span>
                    <p className="mt-1 line-clamp-2 text-sm font-medium">{item.title}</p>
                  </div>
                  <div className="mt-3 flex items-center justify-between border-t pt-2 text-xs">
                    <span className="text-muted-foreground">
                      {item.published_at ? formatWhen(item.published_at) : "Recent"}
                    </span>
                    <a
                      href={item.url}
                      target="_blank"
                      rel="noreferrer"
                      className="flex items-center gap-1 font-medium text-outfield hover:underline"
                    >
                      View Link <ExternalLink className="size-3" />
                    </a>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
