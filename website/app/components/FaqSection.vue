<template>
  <section id="faq" class="scroll-mt-24 px-6 pb-[130px]">
    <div class="mx-auto max-w-[1120px]">
      <div class="reveal mx-auto mb-[70px] max-w-[680px] text-center">
        <div class="mb-4 font-mono text-[11.5px] font-medium uppercase tracking-[0.18em] text-[var(--copper)]">
          FAQ
        </div>
        <h2 class="text-[clamp(30px,4.4vw,48px)] font-extrabold leading-[1.08] tracking-[-0.03em]">
          Straight answers.
        </h2>
        <p class="mt-4 text-[16.5px] text-[var(--mut)]">Including the awkward ones — like Gatekeeper.</p>
      </div>

      <div class="mx-auto max-w-[760px]">
        <div
          v-for="(item, i) in faqs"
          :key="item.q"
          class="reveal mb-3 overflow-hidden rounded-2xl border bg-[var(--panel)] transition-[border-color]"
          :class="open === i ? 'border-[rgba(224,138,76,0.35)]' : 'border-[var(--line)]'"
        >
          <button
            type="button"
            class="flex w-full items-center justify-between gap-4 px-6 py-5 text-left text-base font-semibold tracking-tight text-[var(--text)]"
            :aria-expanded="open === i"
            @click="open = open === i ? null : i"
          >
            {{ item.q }}
            <span
              class="flex size-[26px] shrink-0 items-center justify-center rounded-lg bg-white/5 text-[var(--copper2)] transition"
              :class="open === i ? 'rotate-45 bg-[rgba(224,138,76,0.18)]' : ''"
            >
              +
            </span>
          </button>
          <div
            class="grid transition-[grid-template-rows] duration-300 ease-out"
            :style="{ gridTemplateRows: open === i ? '1fr' : '0fr' }"
          >
            <div class="overflow-hidden">
              <div class="max-w-[660px] px-6 pb-5 text-[14.5px] text-[var(--mut)]">
                <template v-if="item.q === 'How do I install it?'">
                  Download the DMG from GitHub Releases and drag Cuprim into Applications. Current builds are
                  <strong class="text-[var(--text)]">ad-hoc signed</strong> (not notarized yet), so Gatekeeper may block
                  the first launch. Right-click the app and choose
                  <strong class="text-[var(--text)]">Open</strong>, or run
                  <code
                    class="rounded border border-[rgba(224,138,76,0.25)] bg-[rgba(224,138,76,0.1)] px-1.5 py-0.5 font-mono text-[12.5px] text-[var(--copper2)]"
                  >xattr -cr /Applications/Cuprim.app</code>
                  in Terminal.
                </template>
                <template v-else-if="item.q === 'Which Macs are supported?'">
                  Apple Silicon (M1 or later) and
                  <strong class="text-[var(--text)]">macOS 26+</strong>. Intel Macs and older macOS versions are not
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
    a: "Yes. Cuprim is MIT-licensed open source with no subscription, no trial clock, and no upsell. A GitHub star is the only thank-you it asks for.",
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
    a: "No. Cuprim only queries usage and quota endpoints with credentials already on your Mac. It never sees message content, never phones home, and ships with zero analytics SDKs.",
  },
  {
    q: "Which Macs are supported?",
    a: "",
  },
  {
    q: "How do updates work?",
    a: "Cuprim can check GitHub Releases and point you at the newest DMG. Downloads stay manual and verifiable — no silent auto-running updaters.",
  },
]
</script>
