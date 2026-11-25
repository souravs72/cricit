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
  const [useRecovery, setUseRecovery] = useState(true);
  const [emailVal, setEmailVal] = useState("owner@cricit.app");
  const [pwdVal, setPwdVal] = useState("cricit-owner-ok");
  const [codeVal, setCodeVal] = useState("a1b2c3-d4e5f6");
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
        const rawCode = String(form.get("code") ?? "");
        const cleanCode = rawCode.replace(/\s+/g, "").toLowerCase();
        await post("/api/auth/totp", { challenge_id: step.challengeId, code: cleanCode });
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
            <div className="flex items-center justify-between">
              <Label htmlFor="email">Email</Label>
              <button
                type="button"
                onClick={() => {
                  setEmailVal("owner@cricit.app");
                  setPwdVal("cricit-owner-ok");
                }}
                className="text-xs text-muted-foreground hover:text-primary transition-colors"
              >
                Auto-fill Owner
              </button>
            </div>
            <Input
              id="email"
              name="email"
              type="email"
              value={emailVal}
              onChange={(e) => setEmailVal(e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password">Password</Label>
            <Input
              id="password"
              name="password"
              type="password"
              value={pwdVal}
              onChange={(e) => setPwdVal(e.target.value)}
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
            value={codeVal}
            onChange={(e) => setCodeVal(e.target.value)}
            autoComplete="one-time-code"
            placeholder={useRecovery ? "a1b2c3-d4e5f6" : "123456"}
            className="font-mono text-xl tracking-wider"
            autoFocus
            required
          />
          <div className="flex items-center justify-between text-xs pt-1">
            <button
              type="button"
              onClick={() => {
                setUseRecovery((v) => {
                  const next = !v;
                  setCodeVal(next ? "a1b2c3-d4e5f6" : "");
                  return next;
                });
              }}
              className="text-muted-foreground underline-offset-4 hover:underline"
            >
              {useRecovery ? "Use authenticator app code" : "Use recovery code"}
            </button>
            {useRecovery && (
              <span className="text-muted-foreground">
                Demo:{" "}
                <code className="bg-muted px-1.5 py-0.5 rounded text-foreground font-mono">
                  a1b2c3-d4e5f6
                </code>
              </span>
            )}
          </div>
        </div>
      )}

      {error && (
        <div className="space-y-2">
          <p role="alert" className="text-sm text-destructive">
            {error}
          </p>
          {step.kind === "code" && (
            <button
              type="button"
              onClick={() => {
                setError(null);
                setStep({ kind: "password" });
              }}
              className="text-xs text-primary font-medium hover:underline block"
            >
              ← Sign in again with email & password
            </button>
          )}
        </div>
      )}

      <Button type="submit" className="w-full" disabled={pending}>
        {pending ? "Checking…" : step.kind === "password" ? "Continue" : "Sign in"}
      </Button>

      {step.kind === "code" && !error && (
        <div className="text-center pt-2">
          <button
            type="button"
            onClick={() => {
              setError(null);
              setStep({ kind: "password" });
            }}
            className="text-xs text-muted-foreground hover:text-foreground hover:underline"
          >
            ← Back to email & password
          </button>
        </div>
      )}
    </form>
  );
}
