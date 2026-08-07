<template>
  <section id="features" class="scroll-mt-24 px-6 pb-10 pt-[130px]">
    <div class="mx-auto max-w-[1120px]">
      <div class="reveal mx-auto mb-[70px] max-w-[680px] text-center">
        <div class="mb-4 font-mono text-[11.5px] font-medium uppercase tracking-[0.18em] text-[var(--copper)]">
          Features
        </div>
        <h2 class="text-[clamp(30px,4.4vw,48px)] font-extrabold leading-[1.08] tracking-[-0.03em]">
          Everything you need,<br />at the edge of your screen.
        </h2>
        <p class="mt-4 text-[16.5px] text-[var(--mut)]">
          No dashboard, no browser tab, no account. Cuprim lives where your attention already passes — the menu bar.
        </p>
      </div>

      <article
        v-for="(f, i) in features"
        :key="f.title"
        class="reveal grid items-center gap-8 border-t border-[var(--line)] py-12 first:border-t-0 md:grid-cols-2 md:gap-14"
      >
        <div
          class="relative flex min-h-[250px] items-center justify-center overflow-hidden rounded-[22px] border border-[var(--line)] p-8"
          :class="i % 2 === 1 ? 'md:order-2' : ''"
          style="background: linear-gradient(170deg, var(--panel2), var(--panel))"
        >
          <div
            class="pointer-events-none absolute inset-0"
            style="background: radial-gradient(340px 180px at 70% 0%, rgba(224, 138, 76, 0.09), transparent 70%)"
          />

          <!-- bars -->
          <div v-if="f.visual === 'bars'" class="relative z-[1] flex w-full max-w-[300px] flex-col gap-4">
            <div v-for="p in PROVIDERS.slice(0, 3)" :key="p.name" class="flex flex-col gap-1.5">
              <div class="flex justify-between text-xs font-semibold">
                <span>{{ p.name }}</span>
                <span class="font-mono text-[var(--copper2)]">{{ p.pct }}%</span>
              </div>
              <div class="h-[7px] overflow-hidden rounded-full bg-white/10">
                <div
                  class="h-full rounded-full"
                  :style="{
                    width: `${p.pct}%`,
                    background: 'linear-gradient(90deg, var(--copper-deep), var(--copper2))',
                  }"
                />
              </div>
            </div>
          </div>

          <!-- timer -->
          <div v-else-if="f.visual === 'timer'" class="relative z-[1] flex flex-col items-center gap-3.5">
            <div class="relative size-[150px]">
              <svg width="150" height="150" viewBox="0 0 150 150" class="-rotate-90">
                <circle cx="75" cy="75" r="65" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="9" />
                <circle
                  cx="75"
                  cy="75"
                  r="65"
                  fill="none"
                  stroke="var(--copper)"
                  stroke-width="9"
                  stroke-linecap="round"
                  stroke-dasharray="408"
                  stroke-dashoffset="130"
                  style="filter: drop-shadow(0 0 6px rgba(224, 138, 76, 0.6))"
                />
              </svg>
              <div
                class="absolute inset-0 flex items-center justify-center font-mono text-[26px] font-semibold tracking-tight"
              >
                1:12:08
              </div>
            </div>
            <div class="font-mono text-xs text-[var(--mut)]">Claude · 5-hour window</div>
          </div>

          <!-- providers -->
          <div v-else-if="f.visual === 'providers'" class="relative z-[1] flex flex-wrap justify-center gap-3">
            <span
              v-for="p in PROVIDERS"
              :key="p.name"
              class="flex items-center gap-2 rounded-full border border-[var(--line2)] bg-white/5 px-4 py-3 text-[13.5px] font-semibold"
            >
              <i class="size-2 rounded-full" :style="{ background: p.color }" />
              {{ p.name }}
            </span>
          </div>

          <!-- share / light -->
          <div v-else class="relative z-[1] grid w-full max-w-[320px] grid-cols-2 gap-3">
            <div
              v-for="t in tiles"
              :key="t.lab"
              class="rounded-[14px] border border-[var(--line)] bg-white/[0.04] px-4 py-4 text-center"
            >
              <div class="font-mono text-[22px] font-semibold text-[var(--copper2)]">{{ t.num }}</div>
              <div class="mt-1 text-[11px] uppercase tracking-wider text-[var(--dim)]">{{ t.lab }}</div>
            </div>
          </div>
        </div>

        <div :class="i % 2 === 1 ? 'md:order-1' : ''">
          <div
            class="mb-5 flex size-[42px] items-center justify-center rounded-xl border border-[rgba(224,138,76,0.3)] bg-[rgba(224,138,76,0.1)] text-[var(--copper2)]"
          >
            {{ f.icon }}
          </div>
          <h3 class="mb-3 text-2xl font-bold tracking-tight">{{ f.title }}</h3>
          <p class="max-w-[440px] text-[15.5px] text-[var(--mut)]">{{ f.body }}</p>
        </div>
      </article>
    </div>
  </section>
</template>

<script setup lang="ts">
import { PROVIDERS } from "~/utils/site"

const tiles = [
  { num: "Local", lab: "Only" },
  { num: "0", lab: "Telemetry" },
  { num: "1", lab: "Swift binary" },
  { num: "MIT", lab: "License" },
]

const features = [
  {
    icon: "▁",
    title: "Live quota bars",
    body: "Every provider’s remaining usage as honest bars — refreshed when you spend. One glance replaces three browser tabs and a login wall.",
    visual: "bars" as const,
  },
  {
    icon: "◷",
    title: "Reset countdowns",
    body: "Know when Claude’s 5-hour window closes or a weekly pool refreshes. Timers sit in the panel so “am I about to get cut off?” is a glance, not a guess.",
    visual: "timer" as const,
  },
  {
    icon: "▣",
    title: "All your providers, one rim",
    body: "Claude, Codex, Cursor, and Grok side by side. Cuprim reads sessions already on this Mac — no Cuprim account.",
    visual: "providers" as const,
  },
  {
    icon: "◇",
    title: "Native Swift, feather-light",
    body: "Built with SwiftUI — not a browser in a trench coat. Local only, share a clean usage snapshot when you need it, and polling that respects your machine.",
    visual: "light" as const,
  },
]
</script>
