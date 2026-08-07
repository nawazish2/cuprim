const faqs = [
  {
    q: "Who is Cuprim for?",
    a: "Anyone on Apple Silicon macOS 26+ who burns Claude, Codex, Cursor, or Grok quota and wants a glanceable remaining balance.",
  },
  {
    q: "Does Cuprim need an account?",
    a: "Not with us. Sign into the providers you already use on the Mac; Cuprim uses those local sessions.",
  },
  {
    q: "Is it notarized?",
    a: "Not yet. Current releases are ad-hoc signed. If Gatekeeper blocks the first open: right-click Cuprim → Open, or run xattr -cr /Applications/Cuprim.app. We’re honest about this — we don’t pretend it’s notarized.",
  },
  {
    q: "What does it send where?",
    a: "Only to each provider’s usage endpoints, using credentials already on your Mac. Nothing is sent to a Cuprim server — there isn’t one.",
  },
  {
    q: "Mac requirements?",
    a: "Apple Silicon (M1 or later) and macOS 26+. Intel and older macOS are not supported.",
  },
  {
    q: "Windows / iPhone?",
    a: "No. Mac menu bar only.",
  },
  {
    q: "How much does it cost?",
    a: "Free. MIT.",
  },
] as const;

export function FAQ() {
  return (
    <section className="border-t border-white/5" aria-labelledby="faq-heading">
      <div className="mx-auto max-w-3xl px-5 py-20 sm:px-8 sm:py-28">
        <h2
          id="faq-heading"
          className="font-display text-3xl font-semibold tracking-tight text-ink sm:text-4xl"
        >
          FAQ
        </h2>
        <dl className="mt-10 divide-y divide-white/8">
          {faqs.map((item) => (
            <div key={item.q} className="py-6">
              <dt className="font-medium text-ink">{item.q}</dt>
              <dd className="mt-2 text-sm leading-relaxed text-soft">
                {item.q === "Is it notarized?" ? (
                  <>
                    Not yet. Current releases are <strong className="font-medium text-ink/90">ad-hoc signed</strong>.
                    If Gatekeeper blocks the first open: right-click Cuprim → <strong className="font-medium text-ink/90">Open</strong>, or run{" "}
                    <code className="rounded bg-white/5 px-1.5 py-0.5 font-mono text-[12px] text-cyan">
                      xattr -cr /Applications/Cuprim.app
                    </code>
                    . We’re honest about this — we don’t pretend it’s notarized.
                  </>
                ) : (
                  item.a
                )}
              </dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  );
}
