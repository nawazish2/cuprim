<template>
  <nav class="nav sticky top-0 z-50 mb-[-8px] bg-[color-mix(in_srgb,var(--paper)_86%,transparent)] pt-4 backdrop-blur-md">
    <div class="wrap flex items-center justify-between gap-4 py-2">
      <a href="#top" class="flex items-center gap-2.5 text-[1.12rem] font-bold tracking-tight no-underline transition hover:scale-[1.03]">
        <CupLogo :size="28" class="rounded-[7px]" />
        Cuprim
      </a>
      <div class="flex items-center gap-3">
        <a
          :href="SITE.github"
          class="hidden text-[0.93rem] font-medium text-[var(--muted)] no-underline transition hover:text-[var(--ink)] sm:inline"
          target="_blank"
          rel="noopener noreferrer"
          aria-label="View Cuprim on GitHub"
        >
          GitHub
        </a>
        <a :href="SITE.releasesLatest" class="btn !rounded-full !px-4 !py-2 !text-[0.9rem]" target="_blank" rel="noopener noreferrer">
          <span class="hidden sm:inline">Download for Mac</span>
          <span class="sm:hidden">Download</span>
        </a>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
