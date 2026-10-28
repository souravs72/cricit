import type { Metadata } from "next";
import { PostsTable } from "@/components/newsroom/posts-table";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "AI studio" };

/** GET /admin/v1/review — drafts the model wrote. Writes still wait on T15. */

export default async function StudioPage() {
  const { data, error } = await loadOrLogin<PostRow[]>("/admin/v1/review");
  const drafts = (data ?? []).filter((row) => row.prompt_version);
  return (
    <NewsroomShell
      title="AI studio"
      description="Drafts the model wrote. An editor still has to publish; we do not auto-post to readers."
      error={error}
    >
      <p className="mb-4 text-sm text-muted-foreground">
        Prompt on these rows: <span className="font-medium text-foreground">summarize_v1</span>.
        Regenerating a headline is ticket T15.
      </p>
      <PostsTable
        rows={drafts}
        emptyTitle="No model drafts waiting."
        emptyBody="Seeded review cards with a prompt version appear here so you can see the queue."
      />
    </NewsroomShell>
  );
}
