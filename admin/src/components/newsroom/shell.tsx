import type { ReactNode } from "react";

/** Layout chrome for every sidebar page. Importers: dashboard route pages. */

export function NewsroomShell({
  title,
  description,
  error,
  children,
}: {
  title: string;
  description: string;
  error?: string | null;
  children: ReactNode;
}) {
  return (
    <main className="px-6 py-8 md:px-10">
      <header>
        <h1 className="text-4xl font-semibold">{title}</h1>
        <p className="mt-1 max-w-2xl text-muted-foreground">{description}</p>
      </header>
      {error ? (
        <p role="alert" className="mt-8 text-sm text-destructive">
          {error}
        </p>
      ) : (
        <div className="mt-8">{children}</div>
      )}
    </main>
  );
}

export function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-xl border bg-card px-6 py-10 text-center">
      <p className="font-medium">{title}</p>
      <p className="mx-auto mt-1 max-w-md text-sm text-muted-foreground">{body}</p>
    </div>
  );
}
