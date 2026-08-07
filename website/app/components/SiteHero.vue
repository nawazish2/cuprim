<template>
  <header class="hero relative overflow-hidden pb-[72px] pt-[112px]">
    <div
      class="pointer-events-none absolute inset-x-[-10%] top-[-10%] z-0 h-[520px]"
      aria-hidden="true"
      style="
        background:
          radial-gradient(620px 360px at 72% 8%, #0093ff14, transparent 70%),
          radial-gradient(520px 320px at 8% 0, #181b1709, transparent 70%);
      "
    />
    <div class="wrap relative z-[1] text-center">
      <div class="reveal d2 mx-auto mb-7 flex justify-center">
        <CupLogo :size="120" class="rounded-[28px] shadow-[0_18px_50px_-24px_rgba(24,27,23,0.45)]" />
      </div>
      <h1
        class="reveal d2 mx-auto mb-[22px] max-w-[22ch] text-[clamp(2.5rem,5vw,5rem)] font-bold leading-[1.02] tracking-tight"
      >
        Every AI quota,<br />
        right at the <span class="text-[var(--accent)]">rim</span>.
      </h1>
      <p
        class="reveal d3 mx-auto mb-[34px] max-w-[46ch] text-[clamp(1.0625rem,2.5vw,1.3125rem)] font-medium leading-[1.45] text-[var(--muted)]"
      >
        Cuprim watches Claude, Codex, Cursor, and Grok in your Mac menu bar — local only, no telemetry.
      </p>
      <div class="reveal d4 mb-4 flex flex-wrap justify-center gap-3">
        <a :href="SITE.releasesLatest" class="btn btn-lg" target="_blank" rel="noopener noreferrer">
          Download for Mac
        </a>
        <a :href="SITE.github" class="btn btn-lg btn-secondary" target="_blank" rel="noopener noreferrer">
          View on GitHub
        </a>
      </div>
      <p
        class="reveal d4 flex flex-wrap items-center justify-center gap-1 pt-4 font-mono text-[0.82rem] font-medium text-[color-mix(in_srgb,var(--muted)_65%,transparent)]"
      >
        <span>{{ SITE.version }}</span>
        <span class="opacity-65">·</span>
        <span>macOS 26+</span>
        <span class="opacity-65">·</span>
        <span>Apple Silicon</span>
        <span class="opacity-65">·</span>
        <span>MIT</span>
      </p>
    </div>
  </header>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
