import { SITE } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="border-t border-white/5">
      <div className="mx-auto flex max-w-6xl flex-col gap-8 px-5 py-16 sm:px-8 sm:py-20">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="font-display text-2xl font-semibold tracking-tight text-ink">
              Usage at the rim.
            </p>
            <p className="mt-2 text-sm text-soft">Cuprim for Mac — free and open source.</p>
          </div>
          <a
            href={SITE.releasesLatest}
            className="inline-flex w-fit rounded-[10px] bg-accent px-5 py-2.5 text-sm font-semibold text-white transition hover:brightness-110"
            rel="noreferrer"
            target="_blank"
          >
            Download for Mac
          </a>
        </div>
        <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-sm text-soft">
          <a href={SITE.github} className="hover:text-ink" rel="noreferrer" target="_blank">
            GitHub
          </a>
          <a href={SITE.license} className="hover:text-ink" rel="noreferrer" target="_blank">
            MIT License
          </a>
          <a href={SITE.author} className="hover:text-ink" rel="noreferrer" target="_blank">
            Built by Nawazish
          </a>
        </div>
      </div>
    </footer>
  );
}
