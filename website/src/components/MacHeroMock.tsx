const providers = [
  { name: "Claude", remaining: 62, color: "#D97757" },
  { name: "Codex", remaining: 41, color: "#10A37F" },
  { name: "Cursor", remaining: 78, color: "#88C0FF" },
  { name: "Grok", remaining: 55, color: "#E8E8E8" },
];

export function MacHeroMock() {
  return (
    <div
      className="fade-up-delay-2 relative mx-auto w-full max-w-[560px] select-none"
      aria-hidden="true"
    >
      <div className="overflow-hidden rounded-[18px] border border-white/10 bg-[#0a0e14] shadow-[0_40px_80px_-20px_rgba(0,0,0,0.7)]">
        {/* Title bar */}
        <div className="flex items-center gap-2 border-b border-white/5 bg-[#121820] px-3 py-2">
          <span className="size-2.5 rounded-full bg-[#ff5f57]" />
          <span className="size-2.5 rounded-full bg-[#febc2e]" />
          <span className="size-2.5 rounded-full bg-[#28c840]" />
          <span className="ml-3 text-[11px] text-soft/70">Desktop</span>
        </div>

        {/* Desktop */}
        <div className="relative aspect-[16/11] bg-[radial-gradient(ellipse_at_30%_20%,#1a2740_0%,#06080c_55%,#04060a_100%)]">
          {/* Menu bar */}
          <div className="absolute inset-x-0 top-0 flex h-7 items-center justify-between bg-black/35 px-3 text-[10px] text-white/90 backdrop-blur-md">
            <div className="flex items-center gap-3 font-medium">
              <span className="opacity-90"></span>
              <span>Finder</span>
              <span className="opacity-60">File</span>
              <span className="opacity-60">Edit</span>
            </div>
            <div className="flex items-center gap-2.5">
              <span className="opacity-60">Wi‑Fi</span>
              <span className="opacity-60">9:41</span>
              {/* Cuprim gauge */}
              <span className="inline-flex items-center gap-1 rounded-md bg-accent/20 px-1.5 py-0.5 text-cyan">
                <GaugeIcon />
                <span className="font-semibold tabular-nums text-hot">58%</span>
              </span>
            </div>
          </div>

          {/* Soft wallpaper glow */}
          <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_70%_60%,rgba(56,140,255,0.15),transparent_45%)]" />

          {/* Status panel */}
          <div className="absolute top-10 right-3 w-[min(100%,220px)] rounded-[14px] border border-white/10 bg-[#1c1c1e]/88 p-3 shadow-2xl backdrop-blur-xl sm:right-6 sm:w-[240px]">
            <div className="mb-2 flex items-center justify-between">
              <span className="text-xs font-semibold text-ink">Cuprim</span>
              <span className="text-[10px] text-soft">Just now</span>
            </div>
            <ul className="space-y-2">
              {providers.map((p) => (
                <li key={p.name} className="rounded-[8px] bg-white/[0.04] px-2 py-1.5">
                  <div className="mb-1 flex items-center justify-between text-[11px]">
                    <span className="font-medium text-ink/90">{p.name}</span>
                    <span className="tabular-nums text-soft">{p.remaining}%</span>
                  </div>
                  <div className="h-1 overflow-hidden rounded-full bg-white/10">
                    <div
                      className="h-full rounded-full"
                      style={{
                        width: `${p.remaining}%`,
                        background: `linear-gradient(90deg, ${p.color}, #48c4dc)`,
                      }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          </div>

          {/* Desktop hint */}
          <div className="absolute bottom-4 left-4 text-[10px] tracking-wide text-white/25 uppercase">
            Menu bar · local only
          </div>
        </div>
      </div>
    </div>
  );
}

function GaugeIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path
        d="M2.5 12.5a7 7 0 1 1 11 0"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
      />
      <path d="M8 10.5V6.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      <circle cx="8" cy="11.5" r="1.2" fill="currentColor" />
    </svg>
  );
}
