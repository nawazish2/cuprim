const pillars = [
  {
    title: "Local only",
    body: "Credentials stay on your machine. Cuprim only talks to each provider’s own usage API. There is no Cuprim backend.",
  },
  {
    title: "No telemetry",
    body: "The app doesn’t phone home. This site doesn’t load third-party analytics.",
  },
  {
    title: "Open source",
    body: "MIT-licensed. Read the code, build it yourself, or download the release.",
  },
] as const;

export function TrustSection() {
  return (
    <section className="border-t border-white/5" aria-labelledby="trust-heading">
      <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
        <h2
          id="trust-heading"
          className="font-display text-3xl font-semibold tracking-tight text-ink sm:text-4xl"
        >
          Why you can trust it
        </h2>
        <p className="mt-3 max-w-xl text-soft">
          A small Mac utility with a clear privacy stance — and no tracking scripts on this page.
        </p>
        <ul className="mt-12 grid gap-10 sm:grid-cols-3">
          {pillars.map((pillar) => (
            <li key={pillar.title}>
              <h3 className="font-display text-lg font-semibold text-ink">{pillar.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-soft">{pillar.body}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
