<template>
  <section id="faq" class="section section--compact-top">
    <div class="wrap">
      <h2 class="reveal section-title !max-w-none">Questions</h2>
      <p class="reveal section-lead mt-3">
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
            class="flex w-full items-center justify-between gap-3 py-5 text-left text-[1.05rem] font-semibold leading-snug tracking-[-0.02em] transition hover:text-[var(--muted)]"
            :aria-expanded="open === i"
            @click="open = open === i ? null : i"
          >
            {{ item.q }}
            <svg
              class="size-4 shrink-0 text-[var(--muted)] transition duration-300"
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
              <div class="max-w-[58ch] pb-5 pr-0 text-[1rem] leading-relaxed text-[var(--muted)] sm:pr-6">
                <template v-if="item.kind === 'install'">
                  <p>
                    Download the DMG from GitHub Releases and drag Cuprim into Applications.
                    Current builds are ad‑hoc signed (not notarized yet), so macOS may block the first open.
                  </p>
                  <p class="mt-3">
                    Control‑click the app and choose <strong class="font-semibold text-[var(--ink)]">Open</strong>,
                    then confirm. Or clear the quarantine flag in Terminal:
                  </p>
                  <p class="mt-2">
                    <code
                      class="code-snippet"
                    >xattr -cr /Applications/Cuprim.app</code>
                  </p>
                </template>
                <template v-else-if="item.kind === 'macs'">
                  Apple Silicon (M1 or later) running <strong class="font-semibold text-[var(--ink)]">macOS 26</strong> or later.
                  Intel Macs and earlier system versions are not supported.
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
    kind: "plain" as const,
    a: "Yes. MIT-licensed open source — no subscription, no trial, no upsell.",
  },
  {
    q: "How do I install it?",
    kind: "install" as const,
    a: "",
  },
  {
    q: "Which AI providers are supported?",
    kind: "plain" as const,
    a: "Claude, Codex, Cursor, and Grok — using sessions already signed in on your Mac.",
  },
  {
    q: "Does Cuprim read my conversations?",
    kind: "plain" as const,
    a: "No. Cuprim only queries usage and quota endpoints with credentials already on your Mac. It never sees message content and never phones home.",
  },
  {
    q: "Which Macs are supported?",
    kind: "macs" as const,
    a: "",
  },
  {
    q: "How do updates work?",
    kind: "plain" as const,
    a: "Check for Updates downloads and installs from GitHub Releases when a new build exists, and tells you when you’re already on the latest.",
  },
]
</script>
