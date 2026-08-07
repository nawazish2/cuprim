<template>
  <section id="faq" class="section !pt-16">
    <div class="wrap">
      <h2 class="reveal section-title !max-w-none">Frequently Asked Questions</h2>

      <div class="faq-list mx-auto mt-[38px] max-w-[720px] text-left">
        <div
          v-for="(item, i) in faqs"
          :key="item.q"
          class="border-b border-[var(--line-soft)] first:border-t"
          :data-open="open === i"
        >
          <button
            type="button"
            class="flex w-full items-center justify-between gap-3 py-5 text-left text-[1.075rem] font-semibold leading-snug tracking-tight transition hover:text-[var(--muted)]"
            :aria-expanded="open === i"
            @click="open = open === i ? null : i"
          >
            {{ item.q }}
            <svg
              class="size-[18px] shrink-0 text-[var(--muted)] transition duration-300"
              :class="open === i ? 'rotate-180' : ''"
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
            class="grid overflow-hidden transition-[grid-template-rows] duration-300 ease-out"
            :style="{ gridTemplateRows: open === i ? '1fr' : '0fr' }"
          >
            <div class="min-h-0 overflow-hidden">
              <div class="max-w-[62ch] pb-5 pr-7 text-[1.025rem] leading-relaxed text-[var(--muted)]">
                <template v-if="item.q === 'How do I install it?'">
                  Download the DMG from GitHub Releases and drag Cuprim into Applications. Current builds are
                  <strong class="text-[var(--ink)]">ad-hoc signed</strong> (not notarized yet), so Gatekeeper may block
                  the first launch. Right-click the app and choose
                  <strong class="text-[var(--ink)]">Open</strong>, or run
                  <code class="rounded bg-[var(--accent-soft)] px-1.5 py-0.5 font-mono text-[0.9rem] text-[var(--accent-deep)]"
                    >xattr -cr /Applications/Cuprim.app</code
                  >
                  in Terminal.
                </template>
                <template v-else-if="item.q === 'Which Macs are supported?'">
                  Apple Silicon (M1 or later) and
                  <strong class="text-[var(--ink)]">macOS 26+</strong>. Intel Macs and older macOS versions are not
                  supported.
                </template>
                <template v-else>
                  {{ item.a }}
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const open = ref<number | null>(null)

const faqs = [
  {
    q: "Is Cuprim really free?",
    a: "Yes. MIT-licensed open source with no subscription, no trial clock, and no upsell.",
  },
  {
    q: "How do I install it?",
    a: "",
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
    a: "",
  },
  {
    q: "How do updates work?",
    a: "Cuprim can check GitHub Releases and point you at the newest DMG. Downloads stay manual and verifiable.",
  },
]
</script>
