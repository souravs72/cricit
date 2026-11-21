import type { Metadata } from "next";
import { AiStudioManager } from "@/components/newsroom/ai-studio";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Create Story (AI Copilot)" };

export default async function StudioPage() {
  const { data, error } = await loadOrLogin<PostRow[]>("/admin/v1/review");
  const drafts = data ?? [];

  return (
    <NewsroomShell
      title="Create Story (AI Newsroom Copilot)"
      description="Write rough notes, paste breaking match updates, or input a source URL. Our AI Copilot curates your content into a verified 60-word cricket card with Hindi translation, ready for live publishing."
      error={error}
    >
      <AiStudioManager drafts={drafts} />
    </NewsroomShell>
  );
}
