import type { Metadata } from "next";
import { Suspense } from "react";
import { LoginForm } from "./login-form";

export const metadata: Metadata = { title: "Sign in" };

/** A 22-yard strip seen from above: the one bold element on the page. */
function PitchStrip() {
  return (
    <svg viewBox="0 0 120 520" className="h-full max-h-[60vh] w-auto" aria-hidden="true">
      <rect x="20" y="0" width="80" height="520" rx="4" fill="#c9b98f" opacity="0.22" />
      {/* popping and bowling creases at both ends */}
      <g stroke="#ffffff" strokeOpacity="0.75" strokeWidth="1.5">
        <line x1="8" y1="70" x2="112" y2="70" />
        <line x1="28" y1="46" x2="92" y2="46" />
        <line x1="8" y1="450" x2="112" y2="450" />
        <line x1="28" y1="474" x2="92" y2="474" />
        <line x1="28" y1="46" x2="28" y2="70" />
        <line x1="92" y1="46" x2="92" y2="70" />
        <line x1="28" y1="450" x2="28" y2="474" />
        <line x1="92" y1="450" x2="92" y2="474" />
      </g>
      {/* stumps */}
      <g fill="#ffffff" fillOpacity="0.9">
        <circle cx="54" cy="46" r="2.2" />
        <circle cx="60" cy="46" r="2.2" />
        <circle cx="66" cy="46" r="2.2" />
        <circle cx="54" cy="474" r="2.2" />
        <circle cx="60" cy="474" r="2.2" />
        <circle cx="66" cy="474" r="2.2" />
      </g>
      {/* the ball, mid-delivery */}
      <circle cx="63" cy="300" r="5" fill="var(--ball)" />
    </svg>
  );
}

export default function LoginPage() {
  return (
    <main className="grid min-h-dvh md:grid-cols-[1.1fr_1fr]">
      <section className="relative hidden overflow-hidden bg-outfield px-12 py-14 text-white md:flex md:flex-col md:justify-between">
        <div>
          <p className="font-heading text-[clamp(4.5rem,9vw,8.5rem)] font-semibold leading-[0.85] tracking-tight">
            CRICIT
          </p>
          <p className="mt-3 text-lg text-white/80">Newsroom</p>
        </div>
        <div className="absolute inset-y-0 right-16 flex items-center">
          <PitchStrip />
        </div>
        <p className="max-w-xs text-sm text-white/70">
          Every card the app shows is reviewed, edited or published from here.
        </p>
      </section>

      <section className="flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          <p className="font-heading text-3xl font-semibold text-outfield md:hidden">CRICIT</p>
          <h1 className="mt-6 text-4xl font-semibold md:mt-0">Sign in</h1>
          <p className="mt-2 text-muted-foreground">Use the email your owner invited.</p>
          <Suspense>
            <LoginForm />
          </Suspense>
        </div>
      </section>
    </main>
  );
}
