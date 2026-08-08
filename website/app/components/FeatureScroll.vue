<template>
  <section id="features" class="section">
    <div class="wrap">
      <div class="reveal section-eyebrow">features</div>
      <h2 class="reveal section-title">Everything you need at the edge of your screen.</h2>
      <p class="reveal mx-auto mt-3 max-w-[46ch] text-[1.05rem] text-[var(--muted)]">
        No dashboard, no browser tab, no account. Cuprim lives in the menu bar.
      </p>

      <div class="mt-12 grid gap-4 text-left md:grid-cols-2">
        <article
          v-for="f in features"
          :key="f.title"
          class="reveal rounded-[var(--radius)] border border-[var(--line)] bg-[var(--surface)] p-6"
        >
          <h3 class="mb-2 text-[1.08rem] font-semibold tracking-tight">{{ f.title }}</h3>
          <p class="text-[0.95rem] leading-relaxed text-[var(--muted)]">{{ f.body }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const features = [
  {
    title: "Status at a glance",
    body: "Provider plan and remaining quota in the menu bar menu — monochrome, fast, no tabs to open just to check a number.",
  },
  {
    title: "Detail when you need it",
    body: "Open the dashboard panel for honest meters, reset countdowns, and per-provider breakdowns.",
  },
  {
    title: "Four providers, one rim",
    body: "Claude, Codex, Cursor, and Grok side by side. Cuprim reads sessions already signed in on this Mac.",
  },
  {
    title: "Native Swift, local only",
    body: "No Cuprim backend, no telemetry, no account with us. Credentials never leave your machine.",
  },
]
</script>
