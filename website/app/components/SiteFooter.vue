<template>
  <section class="px-6 pb-[90px]">
    <div class="mx-auto max-w-[1120px]">
      <div
        class="reveal relative overflow-hidden rounded-[28px] border border-[rgba(224,138,76,0.3)] px-10 py-[76px] text-center max-sm:px-6"
        style="background: linear-gradient(170deg, #1d150e, #120d09)"
      >
        <div
          class="pointer-events-none absolute inset-0"
          style="background: radial-gradient(600px 260px at 50% 0%, rgba(224, 138, 76, 0.18), transparent 70%)"
        />
        <h2 class="relative text-[clamp(30px,4.4vw,48px)] font-extrabold tracking-tight">
          Bring your quotas<br />
          to the <span class="font-serif-accent">rim</span>.
        </h2>
        <p class="relative mx-auto mt-4 max-w-[520px] text-[var(--mut)]">
          Free, open source, and at home in your menu bar in under a minute. Your limits, finally visible.
        </p>
        <div class="relative mt-8 flex flex-wrap justify-center gap-3.5 max-[560px]:flex-col">
          <a :href="SITE.releasesLatest" class="btn-primary btn-lg max-[560px]:w-full max-[560px]:justify-center" target="_blank" rel="noopener noreferrer">
            Download for Mac
          </a>
          <a :href="SITE.github" class="btn-ghost btn-lg max-[560px]:w-full max-[560px]:justify-center" target="_blank" rel="noopener noreferrer">
            View on GitHub
          </a>
        </div>
      </div>
    </div>
  </section>

  <footer class="border-t border-[var(--line)] px-6 py-11">
    <div class="mx-auto flex max-w-[1120px] flex-wrap items-center gap-6">
      <a href="#top" class="flex items-center gap-2 text-base font-extrabold tracking-tight">
        <CupLogo :size="22" class="text-[var(--copper)]" />
        Cuprim<span class="text-[var(--copper)]">.</span>
      </a>
      <nav class="flex gap-5 text-[13.5px] text-[var(--mut)]" aria-label="Footer">
        <a :href="SITE.github" class="hover:text-[var(--text)]" target="_blank" rel="noopener noreferrer">GitHub</a>
        <a :href="SITE.releases" class="hover:text-[var(--text)]" target="_blank" rel="noopener noreferrer">Releases</a>
        <a :href="SITE.issues" class="hover:text-[var(--text)]" target="_blank" rel="noopener noreferrer">Issues</a>
        <a href="#trust" class="hover:text-[var(--text)]">Privacy</a>
      </nav>
      <div class="ml-auto text-right font-mono text-[11.5px] text-[var(--dim)] max-sm:ml-0 max-sm:text-left">
        © 2026 Cuprim · MIT License<br />
        cup + rim — made for the menu bar
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
