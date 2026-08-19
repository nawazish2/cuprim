<template>
  <section id="faq" class="section section--compact-top">
    <div class="wrap">
      <h2 class="section-title !max-w-none">Questions</h2>
      <p class="section-lead mt-3">
        Straight answers. No marketing stack.
      </p>

      <div class="faq-list mx-auto mt-12 max-w-[640px] text-left">
        <div
          v-for="(item, i) in faqs"
          :key="item.q"
          class="border-b border-[var(--line-soft)] first:border-t"
        >
          <button
            type="button"
            class="flex w-full items-center justify-between gap-3 py-5 text-left text-[1.05rem] font-semibold leading-snug tracking-[-0.02em]"
            :id="`faq-button-${i}`"
            :aria-expanded="open === i"
            :aria-controls="`faq-panel-${i}`"
            @click="open = open === i ? null : i"
          >
            {{ item.q }}
            <svg
              class="size-4 shrink-0 text-[var(--muted)]"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              aria-hidden="true"
            >
              <path d="m6 9 6 6 6-6" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </button>
          <div
            :id="`faq-panel-${i}`"
            role="region"
            :aria-labelledby="`faq-button-${i}`"
            class="faq-panel"
            :class="{ 'is-open': open === i }"
          >
            <p class="max-w-[58ch] pb-5 text-[1rem] leading-relaxed text-[var(--muted)]">
              {{ item.a }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const open = ref<number | null>(null)

onMounted(() => {
  document.documentElement.classList.add("js-enhance")
})

const faqs = [
  {
    q: "Is Cuprim really free?",
    a: "Yes. MIT-licensed open source — no subscription, no trial, no upsell.",
  },
  {
    q: "How do I install it?",
    a: "Download the DMG from GitHub Releases and drag Cuprim into Applications. Current builds are ad-hoc signed, so Control-click → Open the first time, or run xattr -cr /Applications/Cuprim.app.",
  },
  {
    q: "Which AI providers are supported?",
    a: "Claude, Codex, Cursor, and Grok — using sessions already signed in on your Mac.",
  },
  {
    q: "Does Cuprim read my conversations?",
    a: "No. Cuprim only queries usage and quota endpoints with credentials already on your Mac. It never sees message content and never phones home.",
  },
  {
    q: "Which Macs are supported?",
    a: "Apple Silicon (M1 or later) running macOS 26 or later. Intel Macs and earlier system versions are not supported.",
  },
  {
    q: "How do updates work?",
    a: "Check for Updates uses Sparkle to fetch, verify, download, and install from GitHub Releases. It also tells you when you’re already on the latest. Background checks run in release builds.",
  },
]
</script>

<style>
html.js-enhance .faq-panel {
  display: none;
}
html.js-enhance .faq-panel.is-open {
  display: block;
}
</style>
