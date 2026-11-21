"use client";

import type { ReactNode } from "react";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowDown,
  ArrowUp,
  ArrowUpDown,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Clock,
  Copy,
  Edit3,
  ExternalLink,
  Eye,
  Filter,
  Layers,
  LayoutGrid,
  List,
  RotateCcw,
  Search,
  Sparkles,
  Tag as TagIcon,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import { cn } from "@/lib/utils";
import { EmptyState } from "./shell";
import { StoryEditModal } from "./story-edit-dialog";

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

type SortField = "published_at" | "headline" | "category" | "status";
type SortOrder = "asc" | "desc";

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
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [selectedStatus, setSelectedStatus] = useState<string>("all");
  const [selectedKind, setSelectedKind] = useState<string>("all");
  const [selectedTag, setSelectedTag] = useState<string | null>(null);
  const [sortField, setSortField] = useState<SortField>("published_at");
  const [sortOrder, setSortOrder] = useState<SortOrder>("desc");
  const [pageSize, setPageSize] = useState<number>(10);
  const [page, setPage] = useState<number>(1);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<"table" | "cards">("table");
  const [editingPost, setEditingPost] = useState<PostRow | null>(null);

  // Extract unique categories
  const categories = useMemo(() => {
    const set = new Set<string>();
    rows.forEach((r) => r.category && set.add(r.category.toLowerCase()));
    return Array.from(set).sort();
  }, [rows]);

  const allTags = useMemo(() => {
    const counts = new Map<string, number>();
    rows.forEach((r) => {
      (r.tags ?? []).forEach((t) => {
        const clean = t.trim();
        if (clean) counts.set(clean, (counts.get(clean) ?? 0) + 1);
      });
    });
    return Array.from(counts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 15);
  }, [rows]);

  // Filter rows
  const filteredRows = useMemo(() => {
    return rows.filter((row) => {
      // Search
      if (search.trim()) {
        const q = search.toLowerCase();
        const inHeadline = row.headline.toLowerCase().includes(q);
        const inSummary = row.summary?.toLowerCase().includes(q) ?? false;
        const inAuthor = row.author_credit?.toLowerCase().includes(q) ?? false;
        const inDup = row.duplicate_headline?.toLowerCase().includes(q) ?? false;
        const inTags = (row.tags ?? []).some((t) => t.toLowerCase().includes(q));
        if (!inHeadline && !inSummary && !inAuthor && !inDup && !inTags) return false;
      }
      // Category
      if (selectedCategory !== "all" && row.category.toLowerCase() !== selectedCategory) {
        return false;
      }
      // Status
      if (selectedStatus !== "all" && row.status.toLowerCase() !== selectedStatus) {
        return false;
      }
      // Kind
      if (selectedKind !== "all" && row.kind.toLowerCase() !== selectedKind) {
        return false;
      }
      // Tag
      if (selectedTag && !(row.tags ?? []).includes(selectedTag)) {
        return false;
      }
      return true;
    });
  }, [rows, search, selectedCategory, selectedStatus, selectedKind, selectedTag]);

  // Sort rows
  const sortedRows = useMemo(() => {
    return [...filteredRows].sort((a, b) => {
      let cmp = 0;
      if (sortField === "published_at") {
        const tA = a.published_at ? new Date(a.published_at).getTime() : 0;
        const tB = b.published_at ? new Date(b.published_at).getTime() : 0;
        cmp = tA - tB;
      } else if (sortField === "headline") {
        cmp = a.headline.localeCompare(b.headline);
      } else if (sortField === "category") {
        cmp = a.category.localeCompare(b.category);
      } else if (sortField === "status") {
        cmp = a.status.localeCompare(b.status);
      }
      return sortOrder === "asc" ? cmp : -cmp;
    });
  }, [filteredRows, sortField, sortOrder]);

  // Pagination
  const totalPages = Math.max(1, Math.ceil(sortedRows.length / pageSize));
  const currentPage = Math.min(page, totalPages);
  const paginatedRows = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return sortedRows.slice(start, start + pageSize);
  }, [sortedRows, currentPage, pageSize]);

  function handleSort(field: SortField) {
    if (sortField === field) {
      setSortOrder((prev) => (prev === "asc" ? "desc" : "asc"));
    } else {
      setSortField(field);
      setSortOrder("desc");
    }
  }

  function resetFilters() {
    setSearch("");
    setSelectedCategory("all");
    setSelectedStatus("all");
    setSelectedKind("all");
    setSelectedTag(null);
    setPage(1);
  }

  const hasActiveFilters =
    search !== "" ||
    selectedCategory !== "all" ||
    selectedStatus !== "all" ||
    selectedKind !== "all" ||
    selectedTag !== null;

  if (rows.length === 0) {
    return <EmptyState title={emptyTitle} body={emptyBody} />;
  }

  return (
    <div className="space-y-4">
      {/* Top Filter & View Controls */}
      <div className="rounded-xl border border-border/70 bg-card/60 p-4 shadow-2xs backdrop-blur-xs space-y-3">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          {/* Search Box */}
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search by headline, summary, tags, or credit…"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="pl-9 pr-8 bg-background/50 h-9 text-sm"
            />
            {search && (
              <button
                onClick={() => setSearch("")}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>

          {/* Quick Filters & View Switcher */}
          <div className="flex flex-wrap items-center gap-2">
            {/* Category Dropdown */}
            <select
              value={selectedCategory}
              onChange={(e) => {
                setSelectedCategory(e.target.value);
                setPage(1);
              }}
              className="h-9 rounded-md border border-border bg-background px-2.5 text-xs font-medium text-foreground shadow-2xs focus:outline-hidden focus:ring-1 focus:ring-primary"
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c} value={c}>
                  {c.toUpperCase()}
                </option>
              ))}
            </select>

            {/* Status Dropdown */}
            <select
              value={selectedStatus}
              onChange={(e) => {
                setSelectedStatus(e.target.value);
                setPage(1);
              }}
              className="h-9 rounded-md border border-border bg-background px-2.5 text-xs font-medium text-foreground shadow-2xs focus:outline-hidden focus:ring-1 focus:ring-primary"
            >
              <option value="all">All Statuses</option>
              <option value="published">Published</option>
              <option value="review">In Review</option>
              <option value="draft">Draft</option>
              <option value="rejected">Rejected</option>
            </select>

            {/* Kind Dropdown */}
            <select
              value={selectedKind}
              onChange={(e) => {
                setSelectedKind(e.target.value);
                setPage(1);
              }}
              className="h-9 rounded-md border border-border bg-background px-2.5 text-xs font-medium text-foreground shadow-2xs focus:outline-hidden focus:ring-1 focus:ring-primary"
            >
              <option value="all">All Formats</option>
              <option value="article">Article</option>
              <option value="video_short">Video Short</option>
              <option value="ad">Sponsored</option>
            </select>

            {/* View Mode Switcher */}
            <div className="flex items-center gap-0.5 rounded-lg border border-border bg-background p-0.5">
              <button
                type="button"
                onClick={() => setViewMode("table")}
                title="Table view"
                className={cn(
                  "p-1.5 rounded-md transition-colors",
                  viewMode === "table" ? "bg-muted text-foreground" : "text-muted-foreground hover:text-foreground",
                )}
              >
                <List className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => setViewMode("cards")}
                title="Cards view"
                className={cn(
                  "p-1.5 rounded-md transition-colors",
                  viewMode === "cards" ? "bg-muted text-foreground" : "text-muted-foreground hover:text-foreground",
                )}
              >
                <LayoutGrid className="h-4 w-4" />
              </button>
            </div>

            {/* Reset Button */}
            {hasActiveFilters && (
              <Button
                variant="ghost"
                size="sm"
                onClick={resetFilters}
                className="h-9 text-xs text-muted-foreground hover:text-foreground gap-1 px-2.5"
              >
                <RotateCcw className="h-3 w-3" />
                Reset
              </Button>
            )}
          </div>
        </div>

        {/* Tag Pills */}
        {allTags.length > 0 && (
          <div className="flex flex-wrap items-center gap-1.5 pt-1 border-t border-border/40 text-xs text-muted-foreground">
            <span className="flex items-center gap-1 mr-1 text-[11px] font-medium text-muted-foreground/80">
              <TagIcon className="h-3 w-3" /> Popular tags:
            </span>
            {allTags.map(([tag, count]) => {
              const isActive = selectedTag === tag;
              return (
                <button
                  key={tag}
                  onClick={() => {
                    setSelectedTag(isActive ? null : tag);
                    setPage(1);
                  }}
                  className={cn(
                    "inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] transition-colors",
                    isActive
                      ? "bg-primary text-primary-foreground font-semibold"
                      : "bg-muted/70 text-muted-foreground hover:bg-muted hover:text-foreground",
                  )}
                >
                  #{tag}
                  <span className="text-[10px] opacity-70">({count})</span>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Content Rendering: Table vs Cards */}
      {viewMode === "cards" ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {paginatedRows.length === 0 ? (
            <div className="col-span-full py-12 text-center text-muted-foreground">
              No posts match your filters.
            </div>
          ) : (
            paginatedRows.map((row) => (
              <div
                key={row.id}
                className="flex flex-col justify-between rounded-xl border border-border/70 bg-card p-4 shadow-2xs hover:border-border transition-all"
              >
                <div className="space-y-2">
                  <div className="flex items-center justify-between gap-2">
                    <span className="rounded bg-primary/10 px-2 py-0.5 text-[10px] font-bold uppercase text-primary">
                      {row.category}
                    </span>
                    <span
                      className={cn(
                        "inline-flex items-center gap-1 text-[11px] font-medium",
                        row.status === "published" && "text-emerald-600",
                        row.status === "review" && "text-amber-600",
                        row.status === "draft" && "text-muted-foreground",
                        row.status === "rejected" && "text-destructive",
                      )}
                    >
                      <span className={cn(
                        "h-1.5 w-1.5 rounded-full",
                        row.status === "published" && "bg-emerald-500",
                        row.status === "review" && "bg-amber-500",
                        row.status === "draft" && "bg-muted-foreground",
                        row.status === "rejected" && "bg-destructive",
                      )} />
                      {row.status}
                    </span>
                  </div>

                  <h3 className="font-semibold text-sm leading-snug text-foreground line-clamp-2">
                    {row.headline}
                  </h3>

                  {row.summary && (
                    <p className="text-xs text-muted-foreground line-clamp-3 leading-relaxed">
                      {row.summary}
                    </p>
                  )}

                  <div className="flex flex-wrap items-center gap-1 pt-1">
                    {(row.tags ?? []).slice(0, 3).map((t) => (
                      <span key={t} className="rounded bg-muted px-1.5 py-0.5 text-[10px] font-mono text-muted-foreground">
                        #{t}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="mt-4 flex items-center justify-between border-t border-border/60 pt-3 text-[11px] text-muted-foreground">
                  <span className="font-mono">{formatWhen(row.published_at)}</span>
                  <div className="flex items-center gap-1">
                    <Button
                      size="sm"
                      variant="outline"
                      className="h-7 px-2 text-xs gap-1"
                      onClick={() => setEditingPost(row)}
                    >
                      <Edit3 className="h-3 w-3 text-primary" />
                      Edit
                    </Button>
                    <button
                      type="button"
                      title="Copy ID"
                      onClick={() => {
                        navigator.clipboard.writeText(row.id);
                        toast.success("Post ID copied");
                      }}
                      className="p-1 rounded text-muted-foreground hover:bg-muted"
                    >
                      <Copy className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs">
          <Table>
            <TableHeader className="bg-muted/30">
              <TableRow className="hover:bg-transparent">
                <TableHead className="w-[50%]">
                  <button
                    onClick={() => handleSort("headline")}
                    className="flex items-center gap-1.5 font-semibold text-foreground text-xs uppercase tracking-wider"
                  >
                    Headline & Summary
                    {sortField === "headline" ? (
                      sortOrder === "asc" ? (
                        <ArrowUp className="h-3 w-3 text-primary" />
                      ) : (
                        <ArrowDown className="h-3 w-3 text-primary" />
                      )
                    ) : (
                      <ArrowUpDown className="h-3 w-3 text-muted-foreground/50" />
                    )}
                  </button>
                </TableHead>
                <TableHead className="w-[12%]">
                  <button
                    onClick={() => handleSort("category")}
                    className="flex items-center gap-1.5 font-semibold text-foreground text-xs uppercase tracking-wider"
                  >
                    Category
                    {sortField === "category" ? (
                      sortOrder === "asc" ? (
                        <ArrowUp className="h-3 w-3 text-primary" />
                      ) : (
                        <ArrowDown className="h-3 w-3 text-primary" />
                      )
                    ) : (
                      <ArrowUpDown className="h-3 w-3 text-muted-foreground/50" />
                    )}
                  </button>
                </TableHead>
                <TableHead className="w-[11%]">
                  <button
                    onClick={() => handleSort("status")}
                    className="flex items-center gap-1.5 font-semibold text-foreground text-xs uppercase tracking-wider"
                  >
                    Status
                    {sortField === "status" ? (
                      sortOrder === "asc" ? (
                        <ArrowUp className="h-3 w-3 text-primary" />
                      ) : (
                        <ArrowDown className="h-3 w-3 text-primary" />
                      )
                    ) : (
                      <ArrowUpDown className="h-3 w-3 text-muted-foreground/50" />
                    )}
                  </button>
                </TableHead>
                <TableHead className="w-[12%]">
                  <button
                    onClick={() => handleSort("published_at")}
                    className="flex items-center gap-1.5 font-semibold text-foreground text-xs uppercase tracking-wider"
                  >
                    Published
                    {sortField === "published_at" ? (
                      sortOrder === "asc" ? (
                        <ArrowUp className="h-3 w-3 text-primary" />
                      ) : (
                        <ArrowDown className="h-3 w-3 text-primary" />
                      )
                    ) : (
                      <ArrowUpDown className="h-3 w-3 text-muted-foreground/50" />
                    )}
                  </button>
                </TableHead>
                <TableHead className="w-[15%] text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {paginatedRows.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="py-12 text-center text-muted-foreground">
                    No posts match your filters.
                    <Button
                      variant="link"
                      size="sm"
                      onClick={resetFilters}
                      className="ml-2 text-xs text-primary"
                    >
                      Reset all filters
                    </Button>
                  </TableCell>
                </TableRow>
              ) : (
                paginatedRows.map((row) => {
                  const isExpanded = expandedId === row.id;
                  const isHighlighted = row.id === highlightId;
                  const url = safeHttpUrl(row.original_url);

                  return (
                    <TableRow
                      key={row.id}
                      className={cn(
                        "transition-colors group",
                        isHighlighted && "bg-primary/5 border-l-2 border-l-primary",
                      )}
                    >
                      {/* Headline and details */}
                      <TableCell className="align-top py-3.5">
                        <div className="space-y-1">
                          <p className="font-semibold text-foreground text-sm leading-snug group-hover:text-primary transition-colors">
                            {row.headline}
                          </p>

                          {row.summary && (
                            <p className={cn(
                              "text-xs text-muted-foreground leading-relaxed",
                              !isExpanded && "line-clamp-2"
                            )}>
                              {row.summary}
                            </p>
                          )}

                          {row.duplicate_headline && (
                            <div className="flex items-center gap-1.5 rounded-md bg-amber-500/10 px-2 py-1 text-[11px] font-medium text-amber-700 dark:text-amber-400">
                              <Layers className="h-3 w-3 shrink-0" />
                              <span>Possible duplicate of: {row.duplicate_headline}</span>
                            </div>
                          )}

                          {/* Tags and Metadata */}
                          <div className="flex flex-wrap items-center gap-1.5 pt-1">
                            {row.author_credit && (
                              <span className="text-[11px] font-medium text-muted-foreground">
                                By {row.author_credit}
                              </span>
                            )}
                            {(row.tags ?? []).slice(0, 4).map((t) => (
                              <span
                                key={t}
                                className="rounded bg-muted/80 px-1.5 py-0.2 text-[10px] font-mono text-muted-foreground"
                              >
                                #{t}
                              </span>
                            ))}
                            {url && (
                              <a
                                href={url}
                                target="_blank"
                                rel="noreferrer"
                                className="inline-flex items-center gap-0.5 text-[11px] text-primary/80 hover:text-primary hover:underline ml-1"
                              >
                                Source <ExternalLink className="h-2.5 w-2.5" />
                              </a>
                            )}
                          </div>
                        </div>
                      </TableCell>

                      {/* Category */}
                      <TableCell className="align-top py-3.5">
                        <span
                          className={cn(
                            "inline-flex items-center rounded-md px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wide",
                            row.category === "international" && "bg-sky-500/10 text-sky-700 dark:text-sky-300",
                            row.category === "domestic" && "bg-indigo-500/10 text-indigo-700 dark:text-indigo-300",
                            row.category === "grassroots" && "bg-emerald-500/10 text-emerald-700 dark:text-emerald-300",
                            row.category === "ipl" && "bg-amber-500/10 text-amber-700 dark:text-amber-300",
                            !["international", "domestic", "grassroots", "ipl"].includes(row.category) &&
                              "bg-muted text-muted-foreground",
                          )}
                        >
                          {row.category}
                        </span>
                      </TableCell>

                      {/* Status */}
                      <TableCell className="align-top py-3.5">
                        <span
                          className={cn(
                            "inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium",
                            row.status === "published" && "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
                            row.status === "review" && "bg-amber-500/10 text-amber-700 dark:text-amber-400 animate-pulse",
                            row.status === "draft" && "bg-muted text-muted-foreground",
                            row.status === "rejected" && "bg-destructive/10 text-destructive",
                          )}
                        >
                          <span className={cn(
                            "h-1.5 w-1.5 rounded-full",
                            row.status === "published" && "bg-emerald-500",
                            row.status === "review" && "bg-amber-500",
                            row.status === "draft" && "bg-muted-foreground",
                            row.status === "rejected" && "bg-destructive",
                          )} />
                          {row.status}
                        </span>
                      </TableCell>

                      {/* Published Date */}
                      <TableCell className="align-top py-3.5 text-xs text-muted-foreground font-mono tabular-nums whitespace-nowrap">
                        {formatWhen(row.published_at)}
                      </TableCell>

                      {/* Actions */}
                      <TableCell className="align-top py-3.5 text-right">
                        {actions ? (
                          actions(row)
                        ) : (
                          <div className="flex items-center justify-end gap-1">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => setEditingPost(row)}
                              className="h-7 px-2 text-xs gap-1"
                            >
                              <Edit3 className="h-3 w-3 text-primary" />
                              Edit
                            </Button>
                            <button
                              type="button"
                              title="Copy Post ID"
                              onClick={() => {
                                navigator.clipboard.writeText(row.id);
                                toast.success("Post ID copied to clipboard");
                              }}
                              className="p-1 rounded text-muted-foreground hover:bg-muted hover:text-foreground"
                            >
                              <Copy className="h-3.5 w-3.5" />
                            </button>
                            <button
                              type="button"
                              title={isExpanded ? "Collapse" : "Expand summary"}
                              onClick={() => setExpandedId(isExpanded ? null : row.id)}
                              className="p-1 rounded text-muted-foreground hover:bg-muted hover:text-foreground"
                            >
                              <Eye className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Pagination Controls */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between px-1 text-xs text-muted-foreground">
        <div className="flex items-center gap-2">
          <span>Rows per page:</span>
          <select
            value={pageSize}
            onChange={(e) => {
              setPageSize(Number(e.target.value));
              setPage(1);
            }}
            className="rounded border border-border bg-background px-2 py-1 text-xs text-foreground"
          >
            <option value={10}>10</option>
            <option value={25}>25</option>
            <option value={50}>50</option>
            <option value={100}>100</option>
          </select>
          <span className="text-muted-foreground/80">
            Showing{" "}
            <span className="font-semibold text-foreground">
              {filteredRows.length > 0 ? (currentPage - 1) * pageSize + 1 : 0}
            </span>{" "}
            to{" "}
            <span className="font-semibold text-foreground">
              {Math.min(currentPage * pageSize, filteredRows.length)}
            </span>{" "}
            of{" "}
            <span className="font-semibold text-foreground">{filteredRows.length}</span> posts
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={currentPage <= 1}
            className="h-8 gap-1 text-xs"
          >
            <ChevronLeft className="h-3.5 w-3.5" />
            Previous
          </Button>

          <span className="px-2 font-medium text-foreground">
            Page {currentPage} of {totalPages}
          </span>

          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={currentPage >= totalPages}
            className="h-8 gap-1 text-xs"
          >
            Next
            <ChevronRight className="h-3.5 w-3.5" />
          </Button>
        </div>
      </div>

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
