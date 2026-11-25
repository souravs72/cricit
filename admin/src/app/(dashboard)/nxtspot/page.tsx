import type { Metadata } from "next";
import Link from "next/link";
import { ArrowUpRight, Award, MapPin, Radio, Sparkles, User } from "lucide-react";
import { EmptyState, NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { NxtspotRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Nxtspot Grassroots" };

export default async function NxtspotPage() {
  const { data, error } = await loadOrLogin<NxtspotRow[]>("/admin/v1/nxtspot");
  const rows = data ?? [];

  return (
    <NewsroomShell
      title="Nxtspot Grassroots Scouting"
      description="Submissions from cricket grounds, academies, and school tournaments. Editors review talent footage, verify scores, and convert them to live cards."
      badge={
        <span className="rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
          {rows.length} talent entries
        </span>
      }
      actions={
        <Button asChild size="sm" className="gap-1.5 text-xs">
          <Link href="/studio">
            <Sparkles className="h-3.5 w-3.5" />
            AI Draft Studio
          </Link>
        </Button>
      }
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState
          title="No grassroots submissions yet."
          body="Seed includes Anjali Menon (Palakkad) and Rahul Kulkarni (Pune) as sample talent submissions."
        />
      ) : (
        <div className="space-y-4">
          <div className="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs">
            <Table>
              <TableHeader className="bg-muted/30">
                <TableRow>
                  <TableHead className="font-semibold text-xs uppercase tracking-wider">
                    Player / Submitter
                  </TableHead>
                  <TableHead className="font-semibold text-xs uppercase tracking-wider">Location</TableHead>
                  <TableHead className="font-semibold text-xs uppercase tracking-wider">Status</TableHead>
                  <TableHead className="font-semibold text-xs uppercase tracking-wider">
                    Performance Note
                  </TableHead>
                  <TableHead className="font-semibold text-xs uppercase tracking-wider text-right">
                    Actions
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.id} className="hover:bg-muted/30">
                    <TableCell className="py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-700 font-bold text-xs">
                          <User className="h-4 w-4" />
                        </div>
                        <div>
                          <p className="font-semibold text-foreground text-sm">{row.submitter_name}</p>
                          <span className="text-[11px] text-muted-foreground font-mono">
                            ID: {row.id.slice(0, 8)}…
                          </span>
                        </div>
                      </div>
                    </TableCell>

                    <TableCell className="py-3.5 text-xs">
                      {row.location ? (
                        <span className="inline-flex items-center gap-1 text-muted-foreground">
                          <MapPin className="h-3 w-3 text-primary" />
                          {row.location}
                        </span>
                      ) : (
                        "—"
                      )}
                    </TableCell>

                    <TableCell className="py-3.5">
                      <Badge
                        variant="outline"
                        className="bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 font-mono text-[10px]"
                      >
                        {row.status}
                      </Badge>
                    </TableCell>

                    <TableCell className="py-3.5 max-w-md text-xs text-muted-foreground leading-relaxed">
                      {row.raw_text ??
                        "Grassroots talent match highlight and verified bowling/batting figures."}
                    </TableCell>

                    <TableCell className="py-3.5 text-right">
                      <Button asChild size="sm" variant="outline" className="h-8 gap-1 text-xs">
                        <Link href={`/studio?text=${encodeURIComponent(row.raw_text ?? row.submitter_name)}`}>
                          Draft Card <ArrowUpRight className="h-3 w-3" />
                        </Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      )}
    </NewsroomShell>
  );
}
