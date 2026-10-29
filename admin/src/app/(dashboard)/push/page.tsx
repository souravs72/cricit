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
  {
    title: "Bumrah back to number one",
    body: "ICC Test bowling rankings after Perth.",
    audience: "International tab",
    when: "Would send at 10:15 IST",
  },
  {
    title: "RCB retain Kohli",
    body: "Green and Patidar stay. Auction still short a death bowler.",
    audience: "Domestic + IPL",
    when: "Would send at 19:05 IST",
  },
  {
    title: "Jorhat school batter: 164 off 88",
    body: "Meera Sharma’s fourteen sixes, first on Nxtspot.",
    audience: "Nxtspot followers",
    when: "Would send at 20:40 IST",
  },
  {
    title: "WPL super over: Knight Riders hold on",
    body: "Mandhana’s 62, then two runs in the super over.",
    audience: "Readers who follow WPL",
    when: "Would send at 22:10 IST",
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
