"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Bookmark,
  Check,
  CheckCircle2,
  ExternalLink,
  Flame,
  Globe,
  HelpCircle,
  Image as ImageIcon,
  Languages,
  PenTool,
  Radio,
  Send,
  Share2,
  Smartphone,
  Sparkles,
  Video,
} from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { PostRow } from "@/lib/newsroom";
import { proxyJson } from "@/lib/proxy";
import { cn } from "@/lib/utils";

type InputMode = "scratch" | "url" | "drafts";

export function AiStudioManager({ drafts }: { drafts: PostRow[] }) {
  const router = useRouter();

  // Mode: Scratch / Notes, URL, or Pick Draft
  const [mode, setMode] = useState<InputMode>("scratch");

  // Inputs
  const [rawText, setRawText] = useState("");
  const [urlInput, setUrlInput] = useState("");
  const [editorialNotes, setEditorialNotes] = useState("");
  const [category, setCategory] = useState<string>("international");
  const [kind, setKind] = useState<string>("read");

  // Processing state
  const [isCurating, setIsCurating] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [previewHindi, setPreviewHindi] = useState(false);

  // Curated Story Fields
  const [headline, setHeadline] = useState("Gill 104 keeps India in front at Perth");
  const [summary, setSummary] = useState(
    "Shubman Gill's fifth Test hundred dragged India to 287 for 5 after a two-hour rain break. He added 112 with Pant, then saw off Starc with the new ball on a pitch that is starting to stay low.",
  );
  const [headlineHi, setHeadlineHi] = useState("गिल की 104 से पर्थ में भारत आगे");
  const [summaryHi, setSummaryHi] = useState(
    "शुभमन गिल के पाँचवें टेस्ट शतक ने बारिश के बाद भारत को 287/5 तक पहुँचाया। पंत के साथ 112 रन की साझेदारी के बाद उन्होंने स्टार्क को नई गेंद के साथ संभाला।",
  );
  const [authorCredit, setAuthorCredit] = useState("CRICIT Newsroom");
  const [imageUrl, setImageUrl] = useState(
    "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80",
  );
  const [tagsStr, setTagsStr] = useState("India, Test, Gill, Perth");

  const wordCount = summary.trim() ? summary.trim().split(/\s+/).length : 0;

  // Real AI Curation API Call
  async function curateWithAi() {
    setIsCurating(true);
    try {
      const res = await proxyJson<{
        headline: string;
        summary: string;
        headline_hi?: string;
        summary_hi?: string;
        category: string;
        tags: string[];
        image_url?: string;
        author_credit: string;
      }>("admin/v1/curate", {
        method: "POST",
        body: JSON.stringify({
          raw_text: mode === "scratch" ? rawText : undefined,
          url: mode === "url" ? urlInput : undefined,
          category,
          notes: editorialNotes,
        }),
      });

      if (res.headline) setHeadline(res.headline);
      if (res.summary) setSummary(res.summary);
      if (res.headline_hi) setHeadlineHi(res.headline_hi);
      if (res.summary_hi) setSummaryHi(res.summary_hi);
      if (res.category) setCategory(res.category);
      if (res.tags?.length) setTagsStr(res.tags.join(", "));
      if (res.image_url) setImageUrl(res.image_url);
      if (res.author_credit) setAuthorCredit(res.author_credit);

      toast.success("AI Copilot curated story into 60-word format with Hindi translation!");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "AI curation failed. Please check inputs.");
    } finally {
      setIsCurating(false);
    }
  }

  // Publish to Database & Feed
  async function submitStory(status: "published" | "review") {
    setIsPublishing(true);
    try {
      const tags = tagsStr
        .split(",")
        .map((t) => t.trim().replace(/^#/, ""))
        .filter(Boolean);

      await proxyJson("admin/v1/posts", {
        method: "POST",
        body: JSON.stringify({
          headline,
          summary,
          headline_hi: headlineHi || null,
          summary_hi: summaryHi || null,
          category,
          kind,
          tags,
          image_url: imageUrl || null,
          author_credit: authorCredit || "CRICIT Newsroom",
          original_url: urlInput || null,
          status,
        }),
      });

      toast.success(
        status === "published"
          ? "Story published live to mobile feed!"
          : "Story saved to Review Queue for triage.",
      );

      router.push(status === "published" ? "/posts" : "/review");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to save story.");
    } finally {
      setIsPublishing(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Educational Banner Explaining AI Studio */}
      <div className="rounded-xl border border-primary/20 bg-primary/5 p-4 text-xs space-y-1.5">
        <div className="flex items-center gap-2 text-primary font-semibold">
          <HelpCircle className="h-4 w-4 shrink-0" />
          <span>What is AI Studio & How does it work?</span>
        </div>
        <p className="text-muted-foreground leading-relaxed">
          AI Studio is your <strong>cricket newsroom copilot</strong>. Whenever you want to create a story —
          whether from rough match notes, an article link, or a tweet — the AI curates your draft into a
          punchy headline, an Inshorts-style 60-word card, smart cricket tags, and instant Hindi translation.
          You can review and tweak it before publishing live to the mobile app.
        </p>
      </div>

      <div className="grid gap-8 lg:grid-cols-[1.25fr_380px]">
        {/* Left Column: Creator Input & Editor */}
        <div className="space-y-6">
          {/* Step 1: Input Source Selection */}
          <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-xs space-y-4">
            <div className="flex items-center justify-between border-b border-border/60 pb-3">
              <div>
                <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
                  Step 1: Provide Source Content
                </h2>
                <p className="text-xs text-muted-foreground">
                  Choose how you want to input your cricket story.
                </p>
              </div>

              {/* Mode Selection Tabs */}
              <div className="flex items-center gap-1 rounded-lg border border-border bg-muted/40 p-0.5">
                <button
                  type="button"
                  onClick={() => setMode("scratch")}
                  className={cn(
                    "flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-semibold transition-colors",
                    mode === "scratch"
                      ? "bg-background text-foreground shadow-2xs"
                      : "text-muted-foreground hover:text-foreground",
                  )}
                >
                  <PenTool className="h-3 w-3" />
                  Write Notes
                </button>
                <button
                  type="button"
                  onClick={() => setMode("url")}
                  className={cn(
                    "flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-semibold transition-colors",
                    mode === "url"
                      ? "bg-background text-foreground shadow-2xs"
                      : "text-muted-foreground hover:text-foreground",
                  )}
                >
                  <Globe className="h-3 w-3" />
                  Paste URL
                </button>
                {drafts.length > 0 && (
                  <button
                    type="button"
                    onClick={() => setMode("drafts")}
                    className={cn(
                      "flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-semibold transition-colors",
                      mode === "drafts"
                        ? "bg-background text-foreground shadow-2xs"
                        : "text-muted-foreground hover:text-foreground",
                    )}
                  >
                    <Radio className="h-3 w-3" />
                    Pending ({drafts.length})
                  </button>
                )}
              </div>
            </div>

            {/* Mode 1: Write Rough Notes */}
            {mode === "scratch" && (
              <div className="space-y-2">
                <Label htmlFor="raw-notes" className="text-xs font-semibold text-foreground">
                  Rough Match Notes / Scorecard / Player Quotes
                </Label>
                <textarea
                  id="raw-notes"
                  rows={4}
                  value={rawText}
                  onChange={(e) => setRawText(e.target.value)}
                  placeholder="e.g. Sanju Samson 107 off 50 balls with 10 sixes against South Africa in 1st T20I at Durban. India made 202/8 and won by 61 runs. Varun Chakravarthy took 3 wickets."
                  className="w-full rounded-xl border border-border bg-background p-3 text-xs leading-relaxed text-foreground placeholder:text-muted-foreground focus:outline-hidden focus:ring-1 focus:ring-primary"
                />
              </div>
            )}

            {/* Mode 2: Paste Web / YouTube URL */}
            {mode === "url" && (
              <div className="space-y-2">
                <Label htmlFor="url-input" className="text-xs font-semibold text-foreground">
                  Source URL (News Article, Official Tweet, or YouTube Short)
                </Label>
                <Input
                  id="url-input"
                  type="url"
                  value={urlInput}
                  onChange={(e) => setUrlInput(e.target.value)}
                  placeholder="https://www.espncricinfo.com/... or https://youtube.com/shorts/..."
                  className="text-xs"
                />
              </div>
            )}

            {/* Mode 3: Pick Draft from Review Queue */}
            {mode === "drafts" && (
              <div className="space-y-2">
                <Label className="text-xs font-semibold text-foreground">
                  Select an Ingested Story to Polish:
                </Label>
                <div className="divide-y divide-border/60 rounded-xl border border-border bg-muted/20 max-h-48 overflow-y-auto">
                  {drafts.slice(0, 8).map((d) => (
                    <button
                      key={d.id}
                      type="button"
                      onClick={() => {
                        setHeadline(d.headline);
                        if (d.summary) setSummary(d.summary);
                        if (d.category) setCategory(d.category);
                        if (d.author_credit) setAuthorCredit(d.author_credit);
                        if (d.original_url) setUrlInput(d.original_url);
                        toast.success(`Selected story: ${d.headline.slice(0, 40)}…`);
                      }}
                      className="w-full text-left p-3 hover:bg-muted/60 transition-colors flex items-center justify-between gap-3 text-xs"
                    >
                      <span className="font-medium text-foreground truncate">{d.headline}</span>
                      <span className="shrink-0 text-[10px] font-mono uppercase bg-muted px-1.5 py-0.5 rounded">
                        {d.category}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Options Row */}
            <div className="grid grid-cols-2 gap-3 pt-1">
              <div className="space-y-1">
                <Label className="text-xs font-semibold">Category</Label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="h-9 w-full rounded-md border border-border bg-background px-3 text-xs capitalize"
                >
                  <option value="international">International</option>
                  <option value="domestic">Domestic</option>
                  <option value="grassroots">Grassroots (Nxtspot)</option>
                  <option value="ipl">IPL & T20 Leagues</option>
                </select>
              </div>

              <div className="space-y-1">
                <Label className="text-xs font-semibold">Editorial Angle (Optional)</Label>
                <Input
                  value={editorialNotes}
                  onChange={(e) => setEditorialNotes(e.target.value)}
                  placeholder="e.g. Focus on death bowling spell"
                  className="h-9 text-xs"
                />
              </div>
            </div>

            {/* Curate Button */}
            <div className="pt-2">
              <Button
                type="button"
                onClick={curateWithAi}
                disabled={isCurating || (mode === "scratch" && !rawText.trim() && !editorialNotes.trim())}
                className="w-full gap-2 text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold h-10 shadow-sm"
              >
                <Sparkles className="h-4 w-4" />
                {isCurating ? "AI Copilot Curating Story…" : "Curate & Polish Story with AI"}
              </Button>
            </div>
          </div>

          {/* Step 2: Review & Edit Curated Story */}
          <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-xs space-y-4">
            <div className="flex items-center justify-between border-b border-border/60 pb-3">
              <div>
                <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
                  Step 2: Review & Fine-Tune
                </h2>
                <p className="text-xs text-muted-foreground">
                  Tweak the AI-generated copy. Changes update the phone mockup live.
                </p>
              </div>

              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setPreviewHindi((v) => !v)}
                className="gap-1.5 text-xs h-8"
              >
                <Languages className="h-3.5 w-3.5" />
                {previewHindi ? "Show English" : "Show Hindi Translation"}
              </Button>
            </div>

            {/* Headline */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="curated-headline" className="text-xs font-semibold">
                  Headline Hook (English)
                </Label>
                <span className="text-[10px] font-mono text-muted-foreground">
                  {headline.length} / 160 chars
                </span>
              </div>
              <Input
                id="curated-headline"
                value={headline}
                onChange={(e) => setHeadline(e.target.value)}
                maxLength={160}
                className="text-sm font-semibold"
              />
            </div>

            {/* 60-Word Story */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="curated-summary" className="text-xs font-semibold">
                  60-Word Story Summary (English)
                </Label>
                <span
                  className={cn(
                    "text-[10px] font-mono px-1.5 py-0.5 rounded",
                    wordCount >= 45 && wordCount <= 65
                      ? "bg-emerald-500/10 text-emerald-700 font-bold"
                      : "bg-muted text-muted-foreground",
                  )}
                >
                  {wordCount} words {wordCount >= 45 && wordCount <= 65 ? "(Optimal ~60)" : ""}
                </span>
              </div>
              <textarea
                id="curated-summary"
                rows={4}
                value={summary}
                onChange={(e) => setSummary(e.target.value)}
                className="w-full rounded-xl border border-border bg-background p-3 text-xs leading-relaxed text-foreground focus:outline-hidden focus:ring-1 focus:ring-primary"
              />
            </div>

            {/* Hindi Fields (collapsible) */}
            {previewHindi && (
              <div className="space-y-3 rounded-xl border border-border/70 bg-muted/20 p-4 text-xs">
                <div>
                  <Label className="text-[11px] font-semibold">Hindi Headline (शीर्षक)</Label>
                  <Input
                    value={headlineHi}
                    onChange={(e) => setHeadlineHi(e.target.value)}
                    className="mt-1 h-8 text-xs"
                  />
                </div>
                <div>
                  <Label className="text-[11px] font-semibold">Hindi Summary (60 शब्द सारांश)</Label>
                  <textarea
                    rows={3}
                    value={summaryHi}
                    onChange={(e) => setSummaryHi(e.target.value)}
                    className="mt-1 w-full rounded-md border border-border bg-background p-2 text-xs"
                  />
                </div>
              </div>
            )}

            {/* Image URL & Credit */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label className="text-xs font-semibold">Author / Source Credit</Label>
                <Input
                  value={authorCredit}
                  onChange={(e) => setAuthorCredit(e.target.value)}
                  className="h-9 text-xs"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs font-semibold">Tags (comma separated)</Label>
                <Input
                  value={tagsStr}
                  onChange={(e) => setTagsStr(e.target.value)}
                  className="h-9 text-xs font-mono"
                />
              </div>
            </div>

            <div className="space-y-1">
              <Label className="text-xs font-semibold">Header Image URL</Label>
              <Input
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://images.unsplash.com/..."
                className="h-9 text-xs"
              />
            </div>

            {/* Publishing Action Footer */}
            <div className="flex items-center justify-between border-t border-border/60 pt-4">
              <Button
                type="button"
                variant="outline"
                disabled={isPublishing}
                onClick={() => submitStory("review")}
                className="text-xs"
              >
                Save as Review Draft
              </Button>

              <Button
                type="button"
                disabled={isPublishing || !headline.trim() || !summary.trim()}
                onClick={() => submitStory("published")}
                className="gap-2 text-xs bg-emerald-600 hover:bg-emerald-700 text-white font-semibold"
              >
                <Send className="h-3.5 w-3.5" />
                Publish Live to Mobile App
              </Button>
            </div>
          </div>
        </div>

        {/* Right Column: Live Mobile App Inshorts Preview */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold uppercase tracking-wider text-foreground">
              Live Mobile Card Preview
            </h2>
            <Badge variant="outline" className="text-[10px] font-mono">
              Inshorts format
            </Badge>
          </div>

          <div className="mx-auto w-[340px] rounded-3xl border border-border/80 bg-background p-3.5 shadow-2xl">
            {/* Phone Top Notch */}
            <div className="mx-auto mb-3 h-1 w-16 rounded-full bg-border" />

            {/* In-App Category Header Bar */}
            <div className="flex items-center justify-between border-b border-border/40 pb-2 text-[11px] font-medium text-muted-foreground">
              <span className="font-bold text-foreground">CRICIT</span>
              <div className="flex items-center gap-2">
                <span className="rounded bg-primary/10 px-1.5 py-0.5 text-[9px] font-bold uppercase text-primary">
                  {category}
                </span>
                <span className="text-[10px]">1m ago</span>
              </div>
            </div>

            {/* Card Image */}
            <div className="mt-2.5 h-44 w-full overflow-hidden rounded-xl bg-muted relative">
              <img
                src={imageUrl}
                alt="Story banner"
                className="h-full w-full object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).src =
                    "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80";
                }}
              />
              <span className="absolute bottom-2 left-2 rounded-md bg-black/60 px-1.5 py-0.5 text-[9px] font-bold text-white uppercase backdrop-blur-xs">
                {previewHindi ? "हिन्दी" : "ENGLISH"}
              </span>
            </div>

            {/* Card Content */}
            <div className="mt-3 space-y-2">
              <h3 className="font-bold text-sm leading-snug text-foreground">
                {previewHindi && headlineHi ? headlineHi : headline}
              </h3>

              <p className="text-xs text-muted-foreground leading-relaxed">
                {previewHindi && summaryHi ? summaryHi : summary}
              </p>

              {/* Tags in preview */}
              <div className="flex flex-wrap items-center gap-1 pt-1">
                {tagsStr
                  .split(",")
                  .slice(0, 3)
                  .map((t) => (
                    <span
                      key={t}
                      className="rounded bg-muted px-1.5 py-0.5 text-[9px] font-mono text-muted-foreground"
                    >
                      #{t.trim()}
                    </span>
                  ))}
              </div>
            </div>

            {/* Bottom In-App Action Bar */}
            <div className="mt-4 flex items-center justify-between border-t border-border/40 pt-2 text-xs text-muted-foreground">
              <span className="text-[10px] font-medium">Source: {authorCredit}</span>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Share2 className="h-3.5 w-3.5" />
                <Bookmark className="h-3.5 w-3.5" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
