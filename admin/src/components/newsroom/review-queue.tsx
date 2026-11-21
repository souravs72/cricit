"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import {
  AlertTriangle,
  Check,
  CheckCircle2,
  Edit3,
  ExternalLink,
  Flame,
  LayoutGrid,
  List,
  Sparkles,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { formatWhen } from "@/lib/format";
import type { PostRow } from "@/lib/newsroom";
import { proxyJson } from "@/lib/proxy";
import { cn } from "@/lib/utils";
import { PostsTable } from "./posts-table";
import { EmptyState } from "./shell";
import { StoryEditModal } from "./story-edit-dialog";

export function ReviewQueue({ rows }: { rows: PostRow[] }) {
  const router = useRouter();
  const [pending, setPending] = useState<string | null>(null);
  const [focus, setFocus] = useState(0);
  const [viewMode, setViewMode] = useState<"cards" | "table">("cards");
  const [editingPost, setEditingPost] = useState<PostRow | null>(null);

  const act = useCallback(
    async (id: string, action: "publish" | "reject") => {
      setPending(id);
      try {
        await proxyJson(`admin/v1/posts/${id}/${action}`, { method: "POST", body: "{}" });
        toast.success(action === "publish" ? "Card approved and published to live feed" : "Card rejected");
        router.refresh();
      } catch (err) {
        toast.error(err instanceof Error ? err.message : "Could not update that card.");
      } finally {
        setPending(null);
      }
    },
    [router],
  );

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if (editingPost) return; // Don't intercept shortcuts when modal is open
      const row = rows[focus];
      if (!row) return;
      if (e.key === "j" || e.key === "ArrowDown") {
        e.preventDefault();
        setFocus((i) => Math.min(rows.length - 1, i + 1));
      }
      if (e.key === "k" || e.key === "ArrowUp") {
        e.preventDefault();
        setFocus((i) => Math.max(0, i - 1));
      }
      if (e.key === "a") {
        e.preventDefault();
        void act(row.id, "publish");
      }
      if (e.key === "r") {
        e.preventDefault();
        void act(row.id, "reject");
      }
      if (e.key === "e") {
        e.preventDefault();
        setEditingPost(row);
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [rows, focus, act, editingPost]);

  if (rows.length === 0) {
    return (
      <EmptyState
        title="Review queue is clear."
        body="All ingested stories have been triaged. When autonomous ingestion or grassroots submissions need approval, they will appear here."
      />
    );
  }

  return (
    <div className="space-y-5">
      {/* Control bar */}
      <div className="flex flex-col gap-3 rounded-xl border border-border/70 bg-card/60 p-4 backdrop-blur-xs sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2">
          <span className="flex h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
          <p className="text-xs text-muted-foreground font-medium">
            <span className="font-semibold text-foreground">{rows.length}</span> card{rows.length === 1 ? "" : "s"} awaiting editorial sign-off.
          </p>
          <div className="hidden items-center gap-1.5 pl-4 sm:flex text-xs text-muted-foreground/80">
            <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11px]">j/k</span> navigate
            <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11px] ml-1">a</span> approve
            <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11px] ml-1">e</span> edit
            <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11px] ml-1">r</span> reject
          </div>
        </div>

        <div className="flex items-center gap-1 rounded-lg border border-border/80 bg-background p-0.5">
          <button
            onClick={() => setViewMode("cards")}
            className={cn(
              "flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium transition-colors",
              viewMode === "cards"
                ? "bg-primary text-primary-foreground shadow-2xs"
                : "text-muted-foreground hover:text-foreground",
            )}
          >
            <LayoutGrid className="h-3.5 w-3.5" />
            Cards
          </button>
          <button
            onClick={() => setViewMode("table")}
            className={cn(
              "flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium transition-colors",
              viewMode === "table"
                ? "bg-primary text-primary-foreground shadow-2xs"
                : "text-muted-foreground hover:text-foreground",
            )}
          >
            <List className="h-3.5 w-3.5" />
            Table
          </button>
        </div>
      </div>

      {viewMode === "table" ? (
        <PostsTable
          rows={rows}
          emptyTitle="No cards waiting."
          emptyBody="When the worker drafts a card that needs an editor, it shows up here."
          highlightId={rows[focus]?.id}
          actions={(row) => (
            <div className="flex items-center justify-end gap-1.5">
              <Button
                size="sm"
                variant="outline"
                className="h-8 gap-1 text-xs text-emerald-700 hover:bg-emerald-500/10 hover:text-emerald-800 dark:text-emerald-400"
                disabled={pending === row.id}
                onClick={() => act(row.id, "publish")}
              >
                <Check className="h-3 w-3" />
                Approve
              </Button>
              <Button
                size="sm"
                variant="outline"
                className="h-8 gap-1 text-xs text-sky-700 hover:bg-sky-500/10 hover:text-sky-800"
                onClick={() => setEditingPost(row)}
              >
                <Edit3 className="h-3 w-3" />
                Edit
              </Button>
              <Button
                size="sm"
                variant="ghost"
                className="h-8 gap-1 text-xs text-destructive hover:bg-destructive/10"
                disabled={pending === row.id}
                onClick={() => act(row.id, "reject")}
              >
                <X className="h-3 w-3" />
                Reject
              </Button>
            </div>
          )}
        />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {rows.map((row, idx) => {
            const isFocused = idx === focus;
            const isPendingThis = pending === row.id;

            return (
              <div
                key={row.id}
                onClick={() => setFocus(idx)}
                className={cn(
                  "relative flex flex-col justify-between rounded-2xl border bg-card p-5 transition-all shadow-xs",
                  isFocused
                    ? "border-primary ring-2 ring-primary/20 shadow-md"
                    : "border-border/70 hover:border-border",
                )}
              >
                <div className="space-y-3">
                  {/* Card Header Badges */}
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-1.5">
                      <span className="rounded-md bg-primary/10 px-2 py-0.5 text-[11px] font-semibold uppercase text-primary tracking-wide">
                        {row.category}
                      </span>
                      <Badge variant="outline" className="text-[10px] font-mono">
                        {row.kind}
                      </Badge>
                    </div>
                    <span className="text-[11px] font-mono text-muted-foreground">
                      {formatWhen(row.published_at)}
                    </span>
                  </div>

                  {/* Headline */}
                  <h3 className="text-base font-bold leading-snug text-foreground">
                    {row.headline}
                  </h3>

                  {/* Duplicate warning */}
                  {row.duplicate_headline && (
                    <div className="flex items-start gap-2 rounded-xl bg-amber-500/10 p-3 text-xs text-amber-800 dark:text-amber-300">
                      <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5 text-amber-600" />
                      <div>
                        <p className="font-semibold">Possible duplicate alert</p>
                        <p className="mt-0.5 text-[11px] opacity-90">
                          Existing: &ldquo;{row.duplicate_headline}&rdquo;
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Summary */}
                  {row.summary && (
                    <p className="text-xs text-muted-foreground leading-relaxed bg-muted/30 p-3 rounded-lg border border-border/40">
                      {row.summary}
                    </p>
                  )}

                  {/* Author / Source */}
                  <div className="flex flex-wrap items-center gap-2 pt-1 text-xs text-muted-foreground">
                    {row.author_credit && (
                      <span className="font-medium text-foreground/80">Source: {row.author_credit}</span>
                    )}
                    {row.original_url && (
                      <a
                        href={row.original_url}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 text-primary hover:underline"
                      >
                        Original article <ExternalLink className="h-3 w-3" />
                      </a>
                    )}
                  </div>
                </div>

                {/* Bottom Action Footer with 3 Clear Options: Reject, Edit, Approve */}
                <div className="mt-5 flex items-center justify-between border-t border-border/60 pt-4">
                  <div className="flex items-center gap-1 text-[11px] text-muted-foreground">
                    <span className="font-mono">#{idx + 1}</span> of {rows.length}
                  </div>

                  <div className="flex items-center gap-2">
                    <Button
                      size="sm"
                      variant="ghost"
                      disabled={isPendingThis}
                      onClick={() => act(row.id, "reject")}
                      className="h-8 text-xs text-destructive hover:bg-destructive/10"
                    >
                      <X className="h-3.5 w-3.5 mr-1" />
                      Reject
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setEditingPost(row)}
                      className="h-8 text-xs gap-1"
                    >
                      <Edit3 className="h-3.5 w-3.5 text-primary" />
                      Edit Story
                    </Button>
                    <Button
                      size="sm"
                      disabled={isPendingThis}
                      onClick={() => act(row.id, "publish")}
                      className="h-8 text-xs bg-emerald-600 text-white hover:bg-emerald-700 dark:bg-emerald-600 dark:hover:bg-emerald-500"
                    >
                      <Check className="h-3.5 w-3.5 mr-1" />
                      Approve & Publish
                    </Button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Story Edit Modal */}
      {editingPost && (
        <StoryEditModal
          post={editingPost}
          isOpen={Boolean(editingPost)}
          onClose={() => setEditingPost(null)}
          onSaved={() => router.refresh()}
        />
      )}
    </div>
  );
}
