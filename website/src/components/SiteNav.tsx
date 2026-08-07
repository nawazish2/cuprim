import Image from "next/image";
import { SITE } from "@/lib/site";

export function SiteNav() {
  return (
    <header className="sticky top-0 z-50 border-b border-white/5 bg-void/70 backdrop-blur-xl">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-5 sm:px-8">
        <a href="#top" className="flex items-center gap-2.5 font-display text-[15px] font-semibold tracking-tight text-ink">
          <Image src="/icon-192.png" alt="" width={28} height={28} className="rounded-[7px]" />
          Cuprim
        </a>
        <nav className="flex items-center gap-5 text-sm">
          <a
            href={SITE.github}
            className="hidden text-soft transition-colors hover:text-ink sm:inline"
            rel="noreferrer"
            target="_blank"
          >
            GitHub
          </a>
          <a
            href={SITE.releasesLatest}
            className="rounded-[10px] bg-accent px-3.5 py-1.5 font-medium text-white transition hover:brightness-110"
            rel="noreferrer"
            target="_blank"
          >
            Download for Mac
          </a>
        </nav>
      </div>
    </header>
  );
}
