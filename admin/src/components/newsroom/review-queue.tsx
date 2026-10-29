"use client";

/** Approve / reject cards. Callers: admin/src/app/(dashboard)/review/page.tsx.
 * API: POST /api/proxy/admin/v1/posts/{id}/publish and /reject. Schema: PostRow.
 * User: "Check what is tobe built now into this - build it"
 */

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import type { PostRow } from "@/lib/newsroom";
import { proxyJson } from "@/lib/proxy";
import { PostsTable } from "./posts-table";

export function ReviewQueue({ rows }: { rows: PostRow[] }) {
  const router = useRouter();
  const [pending, setPending] = useState<string | null>(null);
  const [focus, setFocus] = useState(0);

  const act = useCallback(
    async (id: string, action: "publish" | "reject") => {
      setPending(id);
      try {
        await proxyJson(`admin/v1/posts/${id}/${action}`, { method: "POST", body: "{}" });
        toast.success(action === "publish" ? "Published" : "Rejected");
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
      const row = rows[focus];
      if (!row) return;
      if (e.key === "j") setFocus((i) => Math.min(rows.length - 1, i + 1));
      if (e.key === "k") setFocus((i) => Math.max(0, i - 1));
      if (e.key === "a") void act(row.id, "publish");
      if (e.key === "r") void act(row.id, "reject");
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [rows, focus, act]);

  return (
    <div className="space-y-4">
      <p className="text-sm text-muted-foreground">
        Keyboard: j/k move, a approve, r reject. Possible duplicates show the existing
        headline so an editor can decide.
      </p>
      <PostsTable
        rows={rows}
        emptyTitle="No cards waiting."
        emptyBody="When the worker drafts a card that needs an editor, it shows up here."
        highlightId={rows[focus]?.id}
        actions={(row) => (
          <div className="flex gap-2">
            <Button
              size="sm"
              disabled={pending === row.id}
              onClick={() => act(row.id, "publish")}
            >
              Approve
            </Button>
            <Button
              size="sm"
              variant="destructive"
              disabled={pending === row.id}
              onClick={() => act(row.id, "reject")}
            >
              Reject
            </Button>
          </div>
        )}
      />
    </div>
  );
}
