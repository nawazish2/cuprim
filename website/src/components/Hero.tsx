import { SITE } from "@/lib/site";
import { MacHeroMock } from "@/components/MacHeroMock";

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden">
      <div className="mx-auto grid max-w-6xl items-center gap-10 px-5 pb-16 pt-14 sm:px-8 lg:grid-cols-[1.05fr_1fr] lg:gap-12 lg:pb-24 lg:pt-20">
        <div className="fade-up">
          <p className="font-display text-sm font-semibold tracking-[0.18em] text-cyan uppercase">
            Cuprim
          </p>
          <h1 className="mt-4 font-display text-[clamp(2.75rem,8vw,4.75rem)] leading-[0.95] font-semibold tracking-tight text-ink">
            Usage
            <br />
            at the rim.
          </h1>
          <p className="mt-5 max-w-md text-base leading-relaxed text-soft sm:text-lg">
            Claude, Codex, Cursor, and Grok quotas in the Mac menu bar — local only, no
            telemetry.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <a
              href={SITE.releasesLatest}
              className="rounded-[10px] bg-accent px-5 py-2.5 text-sm font-semibold text-white transition hover:brightness-110"
              rel="noreferrer"
              target="_blank"
            >
              Download for Mac
            </a>
            <a
              href={SITE.github}
              className="rounded-[10px] border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-medium text-ink transition hover:bg-white/10"
              rel="noreferrer"
              target="_blank"
            >
              View on GitHub
            </a>
          </div>
          <p className="mt-4 text-xs text-soft/80">Apple Silicon · macOS 26+ · MIT</p>
        </div>
        <div className="fade-up-delay min-w-0">
          <MacHeroMock />
        </div>
      </div>
    </section>
  );
}
