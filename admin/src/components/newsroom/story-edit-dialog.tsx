"use client";

import { useState } from "react";
import { Check, Edit3, Image as ImageIcon, Sparkles, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { PostRow } from "@/lib/newsroom";
import { proxyJson } from "@/lib/proxy";

export function StoryEditModal({
  post,
  isOpen,
  onClose,
  onSaved,
}: {
  post: PostRow;
  isOpen: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [headline, setHeadline] = useState(post.headline);
  const [summary, setSummary] = useState(post.summary ?? "");
  const [headlineHi, setHeadlineHi] = useState(post.headline_hi ?? "");
  const [summaryHi, setSummaryHi] = useState(post.summary_hi ?? "");
  const [category, setCategory] = useState(post.category);
  const [tagsStr, setTagsStr] = useState((post.tags ?? []).join(", "));
  const [imageUrl, setImageUrl] = useState(post.image_url ?? "");
  const [authorCredit, setAuthorCredit] = useState(post.author_credit ?? "CRICIT Newsroom");
  const [saving, setSaving] = useState(false);
  const [showHindi, setShowHindi] = useState(Boolean(post.headline_hi || post.summary_hi));

  if (!isOpen) return null;

  const wordCount = summary.trim() ? summary.trim().split(/\s+/).length : 0;

  async function handleSave(publishNow = false) {
    setSaving(true);
    try {
      const tags = tagsStr
        .split(",")
        .map((t) => t.trim().replace(/^#/, ""))
        .filter(Boolean);

      await proxyJson(`admin/v1/posts/${post.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          headline,
          summary,
          headline_hi: headlineHi || null,
          summary_hi: summaryHi || null,
          category,
          tags,
          image_url: imageUrl || null,
          author_credit: authorCredit || null,
          publish_now: publishNow,
          status: publishNow ? "published" : undefined,
        }),
      });

      toast.success(
        publishNow
          ? "Story updated & published live to app!"
          : "Story edits saved successfully",
      );
      onSaved();
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update story.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="relative w-full max-w-2xl max-h-[90vh] flex flex-col rounded-2xl border border-border/80 bg-card shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border/60 px-6 py-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <Edit3 className="h-4 w-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-foreground">Edit Cricket Story</h2>
              <p className="text-xs text-muted-foreground">
                Polish headline, 60-word summary, category, and tags before publishing.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-md p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Form Body (Scrollable) */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {/* Headline */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <Label htmlFor="edit-headline" className="text-xs font-semibold">
                Headline Hook
              </Label>
              <span
                className={`text-[10px] font-mono ${
                  headline.length > 140 ? "text-amber-600 font-bold" : "text-muted-foreground"
                }`}
              >
                {headline.length} / 160 chars
              </span>
            </div>
            <Input
              id="edit-headline"
              value={headline}
              onChange={(e) => setHeadline(e.target.value)}
              maxLength={160}
              className="text-sm font-semibold"
            />
          </div>

          {/* 60-Word Summary */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <Label htmlFor="edit-summary" className="text-xs font-semibold">
                Short Story Summary (Inshorts Format)
              </Label>
              <span
                className={`text-[10px] font-mono px-1.5 py-0.5 rounded ${
                  wordCount > 65
                    ? "bg-amber-500/10 text-amber-700 font-bold"
                    : wordCount >= 45 && wordCount <= 65
                      ? "bg-emerald-500/10 text-emerald-700 font-bold"
                      : "bg-muted text-muted-foreground"
                }`}
              >
                {wordCount} words {wordCount >= 45 && wordCount <= 65 ? "(Optimal ~60)" : ""}
              </span>
            </div>
            <textarea
              id="edit-summary"
              rows={4}
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
              className="w-full rounded-lg border border-border bg-background p-3 text-xs leading-relaxed text-foreground focus:outline-hidden focus:ring-1 focus:ring-primary"
            />
          </div>

          {/* Category & Author Credit */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label htmlFor="edit-category" className="text-xs font-semibold">
                Category
              </Label>
              <select
                id="edit-category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="h-9 w-full rounded-md border border-border bg-background px-3 text-xs font-medium capitalize"
              >
                <option value="international">International</option>
                <option value="domestic">Domestic</option>
                <option value="grassroots">Grassroots</option>
                <option value="ipl">IPL</option>
              </select>
            </div>

            <div className="space-y-1">
              <Label htmlFor="edit-credit" className="text-xs font-semibold">
                Source Credit
              </Label>
              <Input
                id="edit-credit"
                value={authorCredit}
                onChange={(e) => setAuthorCredit(e.target.value)}
                placeholder="e.g. ESPNcricinfo, BCCI"
                className="h-9 text-xs"
              />
            </div>
          </div>

          {/* Tags */}
          <div className="space-y-1">
            <Label htmlFor="edit-tags" className="text-xs font-semibold">
              Tags (comma separated)
            </Label>
            <Input
              id="edit-tags"
              value={tagsStr}
              onChange={(e) => setTagsStr(e.target.value)}
              placeholder="e.g. India, Ranji Trophy, Bumrah"
              className="h-9 text-xs font-mono"
            />
          </div>

          {/* Image URL */}
          <div className="space-y-1">
            <Label htmlFor="edit-image" className="text-xs font-semibold">
              Banner Image URL (Optional)
            </Label>
            <div className="flex gap-2">
              <Input
                id="edit-image"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://..."
                className="h-9 text-xs"
              />
              {imageUrl && (
                <div className="h-9 w-12 shrink-0 overflow-hidden rounded border border-border">
                  <img
                    src={imageUrl}
                    alt="Preview"
                    className="h-full w-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = "none";
                    }}
                  />
                </div>
              )}
            </div>
          </div>

          {/* Optional Hindi Translation Toggle */}
          <div className="pt-2">
            <button
              type="button"
              onClick={() => setShowHindi((v) => !v)}
              className="text-xs font-medium text-primary hover:underline flex items-center gap-1"
            >
              {showHindi ? "− Hide Hindi Translation" : "+ Add / Edit Hindi Translation"}
            </button>

            {showHindi && (
              <div className="mt-3 space-y-3 rounded-xl border border-border/70 bg-muted/20 p-3 text-xs">
                <div>
                  <Label className="text-[11px] font-semibold">Hindi Headline (शीर्षक)</Label>
                  <Input
                    value={headlineHi}
                    onChange={(e) => setHeadlineHi(e.target.value)}
                    placeholder="हिंदी शीर्षक..."
                    className="mt-1 h-8 text-xs"
                  />
                </div>
                <div>
                  <Label className="text-[11px] font-semibold">Hindi Summary (60 शब्द सारांश)</Label>
                  <textarea
                    rows={3}
                    value={summaryHi}
                    onChange={(e) => setSummaryHi(e.target.value)}
                    placeholder="हिंदी में 60 शब्दों का सारांश..."
                    className="mt-1 w-full rounded-md border border-border bg-background p-2 text-xs"
                  />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-between border-t border-border/60 bg-muted/20 px-6 py-3.5">
          <Button variant="ghost" size="sm" onClick={onClose} disabled={saving} className="text-xs">
            Cancel
          </Button>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={saving}
              onClick={() => handleSave(false)}
              className="text-xs"
            >
              Save Changes
            </Button>
            <Button
              size="sm"
              disabled={saving}
              onClick={() => handleSave(true)}
              className="gap-1.5 text-xs bg-emerald-600 hover:bg-emerald-700 text-white"
            >
              <Check className="h-3.5 w-3.5" />
              Save & Publish Live
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
