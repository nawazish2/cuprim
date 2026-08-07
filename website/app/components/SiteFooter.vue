<template>
  <footer class="border-t border-[var(--line)] px-6 pb-14 pt-11 text-center">
    <div class="wrap">
      <div class="mb-8 flex flex-wrap items-center justify-center gap-8">
        <a href="#top" class="flex items-center gap-2.5 text-[1.12rem] font-bold tracking-tight no-underline">
          <CupLogo :size="28" class="rounded-[7px]" />
          Cuprim
        </a>
        <nav class="flex flex-wrap justify-center gap-5" aria-label="Footer">
          <a :href="SITE.github" class="text-[0.93rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">GitHub</a>
          <a :href="SITE.releases" class="text-[0.93rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">Releases</a>
          <a :href="SITE.license" class="text-[0.93rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">License (MIT)</a>
          <a href="#trust" class="text-[0.93rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]">Privacy</a>
        </nav>
      </div>
      <p class="text-[0.84rem] text-[var(--muted)]">
        cup + rim — made for the menu bar · © 2026 Cuprim
      </p>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
