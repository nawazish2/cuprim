<template>
  <section id="trust" class="section">
    <div class="wrap">
      <div class="reveal section-eyebrow">why you can trust it</div>
      <h2 class="reveal section-title">A menu-bar app should earn its place up there.</h2>

      <div class="trust-grid mt-[38px] grid gap-[18px] md:grid-cols-3">
        <article
          v-for="c in cards"
          :key="c.title"
          class="reveal rounded-[var(--radius)] border border-[var(--line)] bg-[var(--surface)] px-[22px] py-6 text-center"
        >
          <h3 class="mb-2.5 flex items-center justify-center gap-2 text-[1.08rem] font-semibold tracking-tight">
            {{ c.title }}
          </h3>
          <p class="text-[0.95rem] leading-relaxed text-[var(--muted)]">
            {{ c.body }}
            <a
              v-if="c.link"
              :href="c.link"
              class="text-[var(--accent-deep)] underline underline-offset-2 hover:text-[var(--accent)]"
              target="_blank"
              rel="noopener noreferrer"
            >See the repo.</a>
          </p>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

const cards = [
  {
    title: "Open source",
    body: "Every line is public. Read it, audit it, or fork it. The code is the proof, not the marketing.",
    link: SITE.github,
  },
  {
    title: "Private by design",
    body: "No account, no telemetry, no analytics SDKs — not even on this website. Credentials stay on your Mac.",
    link: "",
  },
  {
    title: "Free, MIT forever",
    body: "No license wall, no trial clock, no paid tier. If that ever changes, you’ll read it in the README first.",
    link: "",
  },
]
</script>
