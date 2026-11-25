import type { Metadata } from "next";
import { Bell, Flame, Info, Send, Smartphone } from "lucide-react";
import { NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export const metadata: Metadata = { title: "Push Broadcasts" };

const RECENT_BROADCASTS = [
  {
    title: "Gill 104 keeps India in front",
    body: "Fifth Test hundred after the rain delay at Perth.",
    audience: "India Followers",
    when: "Today at 18:30 IST",
    delivered: "24,810 readers",
  },
  {
    title: "Palakkad under-19: 7 for 9",
    body: "Anjali Menon’s magical spell is tonight's top Nxtspot story.",
    audience: "Nxtspot Followers",
    when: "Today at 21:00 IST",
    delivered: "8,920 readers",
  },
  {
    title: "Bumrah back to world number one",
    body: "ICC Test bowling rankings updated after Perth masterclass.",
    audience: "All Cricket",
    when: "Yesterday at 10:15 IST",
    delivered: "31,400 readers",
  },
  {
    title: "RCB retain Kohli & Patidar",
    body: "Retentions announced ahead of the mega auction.",
    audience: "IPL & Domestic",
    when: "Nov 12 at 19:05 IST",
    delivered: "42,100 readers",
  },
];

export default function PushPage() {
  return (
    <NewsroomShell
      title="Push Notifications & Alerts"
      description="Instant mobile breaking news alerts. Composed cards trigger native push notifications to opted-in mobile devices."
      badge={
        <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold text-primary">
          FCM Service Active
        </span>
      }
    >
      <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
        {/* Left: Push Dispatch Composer & Broadcasts Log */}
        <div className="space-y-6">
          <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-xs space-y-4">
            <h2 className="text-base font-bold text-foreground">Compose Breaking News Alert</h2>
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-foreground">Alert Title (Headline)</label>
                <input
                  type="text"
                  placeholder="e.g. India clinch Perth Test by 295 runs"
                  className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
                  defaultValue="Gill 104 keeps India in front"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-foreground">Notification Body</label>
                <textarea
                  rows={2}
                  placeholder="e.g. Fifth Test century in Australia as lead crosses 400."
                  className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
                  defaultValue="Fifth Test hundred after the rain delay at Perth."
                />
              </div>
              <div className="flex flex-wrap items-center justify-between gap-3 pt-2">
                <div className="flex items-center gap-2">
                  <span className="text-xs text-muted-foreground">Target Segment:</span>
                  <select className="h-8 rounded-md border border-border bg-background px-2 text-xs">
                    <option>All Mobile Subscribers</option>
                    <option>India Team Followers</option>
                    <option>IPL & Domestic Only</option>
                    <option>Nxtspot Talent Followers</option>
                  </select>
                </div>

                <Button size="sm" className="gap-1.5 text-xs">
                  <Send className="h-3.5 w-3.5" />
                  Dispatch Test Push
                </Button>
              </div>
            </div>
          </div>

          {/* Broadcasts History */}
          <div className="space-y-3">
            <h2 className="text-base font-bold text-foreground">Recent Dispatches</h2>
            <div className="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs">
              <Table>
                <TableHeader className="bg-muted/30">
                  <TableRow>
                    <TableHead className="text-xs font-semibold uppercase">Notification</TableHead>
                    <TableHead className="text-xs font-semibold uppercase">Segment</TableHead>
                    <TableHead className="text-xs font-semibold uppercase">Timing</TableHead>
                    <TableHead className="text-xs font-semibold uppercase text-right">Reach</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {RECENT_BROADCASTS.map((item, i) => (
                    <TableRow key={i} className="hover:bg-muted/30">
                      <TableCell className="py-3">
                        <p className="font-semibold text-sm text-foreground">{item.title}</p>
                        <p className="text-xs text-muted-foreground">{item.body}</p>
                      </TableCell>
                      <TableCell className="py-3">
                        <Badge variant="outline" className="text-[10px] font-mono">
                          {item.audience}
                        </Badge>
                      </TableCell>
                      <TableCell className="py-3 text-xs font-mono text-muted-foreground">
                        {item.when}
                      </TableCell>
                      <TableCell className="py-3 text-xs font-mono text-right text-emerald-600 font-semibold">
                        {item.delivered}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </div>
        </div>

        {/* Right: Lock Screen Simulator */}
        <div className="space-y-3">
          <h2 className="text-base font-bold text-foreground">Mobile Device Simulator</h2>
          <div className="rounded-3xl border border-border/80 bg-neutral-900 p-4 text-white shadow-xl dark:border-neutral-800">
            <div className="mx-auto mb-4 h-1 w-16 rounded-full bg-neutral-700" />
            <div className="space-y-1 text-center py-4">
              <p className="text-4xl font-extralight tracking-tight">18:32</p>
              <p className="text-xs text-neutral-400 font-medium">Saturday, November 14</p>
            </div>

            {/* Notification Banner */}
            <div className="mt-4 rounded-2xl bg-neutral-800/90 p-3.5 backdrop-blur-md border border-neutral-700/50 shadow-lg space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-neutral-400">
                <div className="flex items-center gap-1.5">
                  <div className="h-4 w-4 rounded bg-primary flex items-center justify-center text-[9px] font-bold text-white">
                    C
                  </div>
                  <span className="font-semibold text-neutral-200">CRICIT</span>
                  <span>·</span>
                  <span>now</span>
                </div>
              </div>
              <p className="font-semibold text-xs text-white">Gill 104 keeps India in front</p>
              <p className="text-[11px] text-neutral-300 leading-snug">
                Fifth Test hundred after the rain delay at Perth. Lead crosses 350.
              </p>
            </div>

            <div className="mt-6 flex justify-around text-neutral-500 text-[10px] border-t border-neutral-800 pt-3">
              <span>Swipe up to read full story</span>
            </div>
          </div>
        </div>
      </div>
    </NewsroomShell>
  );
}
