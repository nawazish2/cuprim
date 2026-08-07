<template>
  <section id="trust" class="scroll-mt-24 px-6 py-[130px]">
    <div class="mx-auto max-w-[1120px]">
      <div class="reveal mx-auto mb-[70px] max-w-[680px] text-center">
        <div class="mb-4 font-mono text-[11.5px] font-medium uppercase tracking-[0.18em] text-[var(--copper)]">
          Why you can trust it
        </div>
        <h2 class="text-[clamp(30px,4.4vw,48px)] font-extrabold leading-[1.08] tracking-[-0.03em]">
          A menu-bar app should earn<br />its place up there.
        </h2>
        <p class="mt-4 text-[16.5px] text-[var(--mut)]">
          The menu bar is prime real estate. Here’s the deal Cuprim makes with you.
        </p>
      </div>

      <div class="grid gap-4 md:grid-cols-3">
        <article
          v-for="(c, i) in cards"
          :key="c.title"
          class="reveal group relative overflow-hidden rounded-[22px] border border-[var(--line)] px-7 py-8 transition hover:-translate-y-1.5 hover:border-[rgba(224,138,76,0.35)] hover:shadow-[0_24px_60px_-20px_rgba(0,0,0,0.7)]"
          :class="i === 1 ? 'd1' : i === 2 ? 'd2' : ''"
          style="background: linear-gradient(170deg, var(--panel2), var(--panel))"
        >
          <div
            class="mb-5 flex size-11 items-center justify-center rounded-xl border border-[rgba(224,138,76,0.3)] bg-[rgba(224,138,76,0.1)] text-[var(--copper2)]"
          >
            {{ c.icon }}
          </div>
          <h3 class="mb-2.5 text-[19px] font-bold tracking-tight">{{ c.title }}</h3>
          <p class="text-[14.5px] text-[var(--mut)]">{{ c.body }}</p>
          <div class="mt-4 border-t border-dashed border-[var(--line2)] pt-3.5 font-mono text-[11px] text-[var(--dim)]">
            {{ c.note }}
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const cards = [
  {
    icon: "</>",
    title: "Open source, MIT",
    body: "Every line lives on GitHub. Inspect it, build it, audit it, fork it. Releases ship alongside the source and packaging scripts.",
    note: "github.com/nawazish2/cuprim · MIT",
  },
  {
    icon: "⛨",
    title: "Private by design",
    body: "No account, no telemetry, no analytics SDKs — not even on this website. Credentials stay on your Mac except to talk to each provider’s own endpoints.",
    note: "0 trackers · 0 analytics · 0 accounts",
  },
  {
    icon: "◎",
    title: "No lock-in, no paywall",
    body: "Free and MIT. If that ever changes, you’ll read it in the README first — not in a billing email.",
    note: "free today · free tomorrow",
  },
]
</script>
