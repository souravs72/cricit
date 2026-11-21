import type { ReactNode } from "react";
import { AlertCircle, Inbox } from "lucide-react";

/** Layout chrome for every sidebar page. Importers: dashboard route pages. */

export function NewsroomShell({
  title,
  description,
  error,
  badge,
  actions,
  children,
}: {
  title: string;
  description: string;
  error?: string | null;
  badge?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <main className="flex-1 p-6 md:p-8 max-w-7xl">
      <header className="flex flex-col gap-4 border-b border-border/60 pb-6 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-foreground md:text-3xl">
              {title}
            </h1>
            {badge}
          </div>
          <p className="mt-1 text-sm text-muted-foreground max-w-3xl leading-relaxed">
            {description}
          </p>
        </div>
        {actions && <div className="flex items-center gap-2 shrink-0">{actions}</div>}
      </header>

      {error ? (
        <div className="mt-6 flex items-start gap-3 rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-sm text-destructive">
          <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />
          <div>
            <p className="font-semibold">Unable to load data</p>
            <p className="mt-0.5 text-xs text-destructive/80">{error}</p>
          </div>
        </div>
      ) : (
        <div className="mt-6">{children}</div>
      )}
    </main>
  );
}

export function EmptyState({
  title,
  body,
  action,
}: {
  title: string;
  body: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border/80 bg-card/40 px-6 py-14 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted/80 text-muted-foreground mb-4">
        <Inbox className="h-6 w-6" />
      </div>
      <p className="text-base font-semibold text-foreground">{title}</p>
      <p className="mt-1 max-w-md text-sm text-muted-foreground">{body}</p>
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}
