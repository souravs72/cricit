import type { Metadata } from "next";
import { CheckCircle2, ShieldAlert, ShieldCheck, UserCheck } from "lucide-react";
import { EmptyState, NewsroomShell } from "@/components/newsroom/shell";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { loadOrLogin } from "@/lib/api/server";
import { formatWhen } from "@/lib/format";
import type { AuditRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Security Audit Log" };

export default async function AuditPage() {
  const { data, error } = await loadOrLogin<AuditRow[]>("/admin/v1/audit");
  const rows = data ?? [];

  return (
    <NewsroomShell
      title="Security & System Audit Log"
      description="Immutable ledger of administrator authentications, 2FA verifications, editorial publishes, and background sync operations."
      badge={
        <span className="rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-400">
          {rows.length} Events Recorded
        </span>
      }
      error={error}
    >
      {rows.length === 0 ? (
        <EmptyState
          title="No audit entries found."
          body="Administrator sign-ins and content approvals will log events here."
        />
      ) : (
        <div className="overflow-hidden rounded-xl border border-border/70 bg-card shadow-xs">
          <Table>
            <TableHeader className="bg-muted/30">
              <TableRow>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">Timestamp</TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">Action Event</TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">Entity</TableHead>
                <TableHead className="font-semibold text-xs uppercase tracking-wider">
                  Details / Audit Note
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => {
                const isFail = row.action.includes("fail") || row.action.includes("reject");
                const isAuth = row.action.includes("login") || row.action.includes("totp");

                return (
                  <TableRow key={row.id} className="hover:bg-muted/30">
                    <TableCell className="py-3.5 text-xs font-mono tabular-nums text-muted-foreground whitespace-nowrap">
                      {formatWhen(row.ts)}
                    </TableCell>

                    <TableCell className="py-3.5">
                      <span
                        className={`inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-xs font-mono font-medium ${
                          isFail
                            ? "bg-destructive/10 text-destructive"
                            : isAuth
                              ? "bg-primary/10 text-primary"
                              : "bg-muted text-foreground"
                        }`}
                      >
                        {isFail ? (
                          <ShieldAlert className="h-3 w-3 shrink-0" />
                        ) : (
                          <ShieldCheck className="h-3 w-3 shrink-0" />
                        )}
                        {row.action}
                      </span>
                    </TableCell>

                    <TableCell className="py-3.5 text-xs font-medium text-foreground">{row.entity}</TableCell>

                    <TableCell className="py-3.5 text-xs text-muted-foreground">
                      {row.note ?? "Standard event logged by security middleware."}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      )}
    </NewsroomShell>
  );
}
