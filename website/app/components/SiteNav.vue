<template>
  <nav class="nav sticky top-0 z-50 px-3 pt-3 sm:px-4 sm:pt-4" aria-label="Primary">
    <div class="nav-pill mx-auto max-w-[960px] rounded-[26px] px-2.5 py-2 sm:px-3.5 sm:py-2.5 md:rounded-full">
      <div class="flex items-center justify-between gap-2 sm:gap-4">
        <a href="#top" class="group flex min-w-0 items-center gap-2 no-underline sm:gap-2.5">
          <CupLogo :size="28" class="shrink-0 rounded-[7px] shadow-[0_2px_8px_-4px_rgba(0,0,0,0.35)]" />
          <span class="text-[1.05rem] font-bold tracking-tight text-[var(--ink)] sm:text-[1.12rem]">
            Cuprim
          </span>
        </a>

        <div class="hidden items-center gap-5 md:flex">
          <a
            v-for="link in links"
            :key="link.href"
            :href="link.href"
            class="nav-link text-[0.9rem] font-medium no-underline"
          >
            {{ link.label }}
          </a>
        </div>

        <a
          :href="SITE.releasesLatest"
          class="btn btn-nav shrink-0 !rounded-full !px-3.5 !py-2 !text-[0.88rem] sm:!px-4 sm:!text-[0.9rem]"
          target="_blank"
          rel="noopener noreferrer"
        >
          <AppleMark class="size-[13px] shrink-0 opacity-95" />
          <span class="hidden sm:inline">Download Cuprim</span>
          <span class="sm:hidden">Download</span>
          <span class="sr-only"> (opens in a new tab)</span>
        </a>
      </div>

      <div class="mobile-links -mx-1 flex gap-2 overflow-x-auto px-1 md:hidden" aria-label="Sections">
        <a
          v-for="link in links"
          :key="link.href"
          :href="link.href"
          class="nav-link inline-flex shrink-0 items-center px-1.5 py-3 text-[0.85rem] font-medium no-underline"
        >
          {{ link.label }}
        </a>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

const links = [
  { href: "#glance", label: "Glance" },
  { href: "#providers", label: "Providers" },
  { href: "#privacy", label: "Privacy" },
  { href: "#install", label: "Install" },
  { href: "#faq", label: "FAQ" },
] as const
</script>

<style scoped>
.nav {
  background: transparent;
  isolation: isolate;
}

.nav-pill {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  background:
    linear-gradient(
      180deg,
      color-mix(in srgb, #fff 55%, transparent) 0%,
      color-mix(in srgb, #fff 22%, transparent) 100%
    ),
    color-mix(in srgb, var(--paper) 28%, transparent);
  border: 1px solid color-mix(in srgb, #fff 72%, var(--line));
  box-shadow:
    0 1px 0 color-mix(in srgb, #fff 88%, transparent) inset,
    0 12px 40px -16px rgba(24, 27, 23, 0.38);
  backdrop-filter: blur(28px) saturate(1.55);
  -webkit-backdrop-filter: blur(28px) saturate(1.55);
}

.nav-pill > * {
  position: relative;
  z-index: 1;
}

.nav-link {
  color: color-mix(in srgb, var(--muted) 92%, var(--ink));
}

.nav-link:hover {
  color: var(--ink);
}
</style>
