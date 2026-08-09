<template>
  <nav class="nav sticky top-0 z-50 px-3 pt-3 sm:px-4 sm:pt-4" aria-label="Primary">
    <div class="nav-pill mx-auto flex max-w-[960px] items-center justify-between gap-2 rounded-full px-2.5 py-2 sm:gap-4 sm:px-3.5 sm:py-2.5">
      <a
        href="#top"
        class="group flex min-w-0 items-center gap-2 no-underline sm:gap-2.5"
      >
        <CupLogo :size="28" class="shrink-0 rounded-[7px] shadow-[0_2px_8px_-4px_rgba(0,0,0,0.35)]" />
        <span class="relative flex items-baseline gap-1.5">
          <span class="text-[1.05rem] font-bold tracking-tight text-[var(--ink)] sm:text-[1.12rem]">
            Cuprim
          </span>
          <span class="nav-chip hidden sm:inline">
            {{ SITE.version }}
          </span>
        </span>
      </a>

      <div class="hidden items-center gap-5 md:flex" aria-label="Sections">
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
        <span class="hidden sm:inline">Download for Mac</span>
        <span class="sm:hidden">Download</span>
      </a>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

const links = [
  { href: "#features", label: "Features" },
  { href: "#trust", label: "Trust" },
  { href: "#faq", label: "FAQ" },
] as const
</script>

<style scoped>
.nav {
  /* Let page content scroll under the pill so frost is visible */
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
    0 -0.5px 0 color-mix(in srgb, var(--ink) 6%, transparent) inset,
    0 1px 2px color-mix(in srgb, var(--ink) 4%, transparent),
    0 12px 40px -16px rgba(24, 27, 23, 0.38),
    0 0 0 0.5px color-mix(in srgb, var(--ink) 5%, transparent);
  backdrop-filter: blur(28px) saturate(1.55) brightness(1.05);
  -webkit-backdrop-filter: blur(28px) saturate(1.55) brightness(1.05);
}

.nav-pill::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  background: linear-gradient(
    115deg,
    color-mix(in srgb, #fff 38%, transparent) 0%,
    transparent 42%,
    color-mix(in srgb, #0073eb 5%, transparent) 100%
  );
  opacity: 0.9;
  z-index: 0;
}

.nav-pill > * {
  position: relative;
  z-index: 1;
}

.nav-chip {
  border-radius: 999px;
  padding: 2px 7px;
  font-size: 0.62rem;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--muted);
  background: color-mix(in srgb, var(--surface) 45%, transparent);
  border: 1px solid color-mix(in srgb, #fff 55%, var(--line));
  box-shadow: 0 1px 0 color-mix(in srgb, #fff 60%, transparent) inset;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.nav-link {
  color: color-mix(in srgb, var(--muted) 92%, var(--ink));
  transition: color 0.15s ease;
}

.nav-link:hover {
  color: var(--ink);
}

@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .nav-pill {
    background: color-mix(in srgb, var(--surface) 92%, var(--paper));
  }
}
</style>
