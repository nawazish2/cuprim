const features = [
  {
    title: "See what’s left without leaving focus.",
    body: "A compact gauge lives in the menu bar. Click for a native status menu; open the panel when you want the full picture.",
    label: "Menu bar",
  },
  {
    title: "One glass panel for every quota that matters.",
    body: "Claude, Codex, Cursor, and Grok side by side. Cuprim reads what you’re already signed into on this Mac.",
    label: "Providers",
  },
  {
    title: "Ship a clean usage card.",
    body: "Copy a dark share card for Slack or social — same numbers, no screenshot crop gymnastics.",
    label: "Share",
  },
] as const;

export function FeatureScroll() {
  return (
    <section className="border-t border-white/5" aria-labelledby="features-heading">
      <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
        <h2 id="features-heading" className="sr-only">
          Features
        </h2>
        <div className="space-y-20 sm:space-y-28">
          {features.map((feature, index) => (
            <article
              key={feature.label}
              className="grid gap-6 lg:grid-cols-[0.9fr_1.1fr] lg:items-center lg:gap-16"
            >
              <div className={index % 2 === 1 ? "lg:order-2" : undefined}>
                <p className="text-xs font-semibold tracking-[0.16em] text-cyan uppercase">
                  {feature.label}
                </p>
                <h3 className="mt-3 font-display text-2xl leading-snug font-semibold tracking-tight text-ink sm:text-3xl">
                  {feature.title}
                </h3>
                <p className="mt-4 max-w-md text-base leading-relaxed text-soft">{feature.body}</p>
              </div>
              <div
                className={`rounded-[14px] border border-white/8 bg-mist/60 p-6 ${index % 2 === 1 ? "lg:order-1" : ""}`}
              >
                <FeatureVisual index={index} />
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function FeatureVisual({ index }: { index: number }) {
  if (index === 0) {
    return (
      <div className="flex h-36 items-center justify-center rounded-[10px] bg-void/80">
        <div className="flex items-center gap-3 rounded-full border border-white/10 bg-black/40 px-4 py-2 text-sm text-ink backdrop-blur">
          <span className="text-cyan">◉</span>
          <span className="font-medium">Cuprim</span>
          <span className="tabular-nums text-hot">58% left</span>
        </div>
      </div>
    );
  }
  if (index === 1) {
    return (
      <div className="grid grid-cols-2 gap-2">
        {["Claude", "Codex", "Cursor", "Grok"].map((name) => (
          <div
            key={name}
            className="rounded-[10px] border border-white/8 bg-void/70 px-3 py-4 text-center text-sm font-medium text-ink"
          >
            {name}
          </div>
        ))}
      </div>
    );
  }
  return (
    <div className="rounded-[10px] border border-white/8 bg-black px-4 py-5">
      <p className="text-xs text-soft">Share card</p>
      <p className="mt-2 text-sm font-medium text-ink">Monitor Your AI Subscriptions with Cuprim</p>
      <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-white/10">
        <div className="h-full w-3/5 rounded-full bg-accent" />
      </div>
    </div>
  );
}
