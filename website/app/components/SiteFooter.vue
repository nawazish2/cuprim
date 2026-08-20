<template>
  <footer class="border-t border-[var(--line)] px-4 pb-12 pt-10 text-center sm:px-6 sm:pb-16 sm:pt-12">
    <div class="wrap">
      <div class="mb-7 flex flex-wrap items-center justify-center gap-7">
        <a href="#top" class="flex items-center gap-2.5 text-[1.08rem] font-semibold tracking-[-0.02em] no-underline">
          <CupLogo :size="26" class="rounded-[6px]" />
          Cuprim
        </a>
        <nav class="flex flex-wrap justify-center gap-1" aria-label="Footer">
          <a :href="SITE.github" class="inline-flex items-center px-2 py-3 text-[0.9rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">GitHub</a>
          <a :href="SITE.releases" class="inline-flex items-center px-2 py-3 text-[0.9rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">Releases</a>
          <a :href="SITE.license" class="inline-flex items-center px-2 py-3 text-[0.9rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]" target="_blank" rel="noopener noreferrer">License (MIT)</a>
          <a href="#privacy" class="inline-flex items-center px-2 py-3 text-[0.9rem] text-[var(--muted)] no-underline transition hover:text-[var(--ink)]">Privacy</a>
        </nav>
      </div>
      <p class="text-[0.78rem] font-medium tracking-[-0.01em] text-[var(--muted)]">
        Requires macOS 26 or later · Apple silicon
      </p>
      <p class="mt-2 text-[0.78rem] text-[color-mix(in_srgb,var(--muted)_80%,transparent)]">
        Created by Nawazish · © 2026 Cuprim
      </p>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
