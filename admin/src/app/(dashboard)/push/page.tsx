import type { Metadata } from "next";
import { NewsroomShell } from "@/components/newsroom/shell";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export const metadata: Metadata = { title: "Push" };

/** Example compositions only. Sending waits on T24 (FCM). No live send API. */

const EXAMPLES = [
  {
    title: "Gill 104 keeps India in front",
    body: "Fifth Test hundred after the rain delay at Perth.",
    audience: "Readers who follow India",
    when: "Would send at 18:30 IST",
  },
  {
    title: "Palakkad under-19: 7 for 9",
    body: "Anjali Menon’s spell is the Nxtspot story tonight.",
    audience: "Nxtspot followers",
    when: "Would send at 21:00 IST",
  },
];

export default function PushPage() {
  return (
    <NewsroomShell
      title="Push"
      description="Compose a notification. Delivery is ticket T24 — these two rows are the shape an editor would send, not a live blast."
    >
      <div className="overflow-hidden rounded-xl border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Title</TableHead>
              <TableHead>Body</TableHead>
              <TableHead>Audience</TableHead>
              <TableHead>Schedule</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {EXAMPLES.map((row) => (
              <TableRow key={row.title}>
                <TableCell className="font-medium">{row.title}</TableCell>
                <TableCell className="max-w-sm whitespace-normal text-muted-foreground">
                  {row.body}
                </TableCell>
                <TableCell>{row.audience}</TableCell>
                <TableCell>{row.when}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </NewsroomShell>
  );
}
