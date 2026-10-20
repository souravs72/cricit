"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type Step = { kind: "password" } | { kind: "code"; challengeId: string };

async function post(url: string, data: unknown) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body?.error?.message ?? "Sign-in failed. Try again.");
  return body;
}

export function LoginForm() {
  const router = useRouter();
  const next = useSearchParams().get("next");
  const [step, setStep] = useState<Step>({ kind: "password" });
  const [useRecovery, setUseRecovery] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setPending(true);
    const form = new FormData(e.currentTarget);
    try {
      if (step.kind === "password") {
        const { challenge_id } = await post("/api/auth/login", {
          email: form.get("email"),
          password: form.get("password"),
        });
        setStep({ kind: "code", challengeId: challenge_id });
      } else {
        await post("/api/auth/totp", { challenge_id: step.challengeId, code: form.get("code") });
        // Only same-site relative paths are allowed as a post-login destination.
        router.replace(next?.startsWith("/") && !next.startsWith("//") ? next : "/overview");
        router.refresh();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed. Try again.");
    } finally {
      setPending(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="mt-8 space-y-5" noValidate>
      {step.kind === "password" ? (
        <>
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" name="email" type="email" autoComplete="username" required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password">Password</Label>
            <Input
              id="password"
              name="password"
              type="password"
              autoComplete="current-password"
              required
              minLength={12}
            />
          </div>
        </>
      ) : (
        <div className="space-y-2">
          <Label htmlFor="code">{useRecovery ? "Recovery code" : "Code from your authenticator app"}</Label>
          <Input
            id="code"
            name="code"
            autoComplete="one-time-code"
            inputMode={useRecovery ? "text" : "numeric"}
            pattern={useRecovery ? "[0-9a-f]{6}-[0-9a-f]{6}" : "\\d{6}"}
            maxLength={useRecovery ? 13 : 6}
            placeholder={useRecovery ? "a1b2c3-d4e5f6" : "123456"}
            className="font-heading text-2xl tracking-[0.3em]"
            autoFocus
            required
          />
          <button
            type="button"
            onClick={() => setUseRecovery((v) => !v)}
            className="text-sm text-muted-foreground underline-offset-4 hover:underline"
          >
            {useRecovery ? "Use the authenticator code instead" : "Use a recovery code"}
          </button>
        </div>
      )}

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}

      <Button type="submit" className="w-full" disabled={pending}>
        {pending ? "Checking…" : step.kind === "password" ? "Continue" : "Sign in"}
      </Button>
    </form>
  );
}
