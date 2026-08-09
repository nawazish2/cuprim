<template>
  <header class="hero relative overflow-x-clip pb-12 pt-[88px] sm:pb-16 sm:pt-[112px]">
    <div
      class="pointer-events-none absolute inset-x-0 top-0 z-0 h-[420px]"
      aria-hidden="true"
      style="
        background:
          radial-gradient(580px 300px at 70% 0%, #0073eb12, transparent 68%),
          radial-gradient(480px 280px at 12% 8%, #181b1708, transparent 65%);
      "
    />
    <div class="wrap relative z-[1] text-center">
      <div class="reveal d2 mx-auto mb-5 flex justify-center">
        <CupLogo :size="72" class="rounded-[18px] shadow-[0_14px_40px_-22px_rgba(24,27,23,0.5)]" />
      </div>
      <h1
        class="reveal d2 mx-auto mb-4 max-w-[18ch] text-[clamp(2.35rem,5.2vw,4.25rem)] font-semibold leading-[1.02] tracking-[-0.035em]"
      >
        Every AI quota,<br />
        right at the <span class="text-[var(--accent)]">rim</span>.
      </h1>
      <p
        class="reveal d3 mx-auto mb-7 max-w-[40ch] text-[clamp(1.05rem,2.2vw,1.22rem)] font-normal leading-[1.4] text-[var(--muted)]"
      >
        Claude, Codex, Cursor, and Grok — live in the menu bar. Local only. No telemetry.
      </p>
      <div class="reveal d4 mb-3 flex w-full max-w-sm flex-col items-stretch gap-2 sm:mx-auto sm:max-w-none sm:flex-row sm:items-center sm:justify-center sm:gap-3">
        <a :href="SITE.releasesLatest" class="btn btn-lg w-full sm:w-auto" target="_blank" rel="noopener noreferrer">
          <AppleMark class="size-[15px] shrink-0 opacity-95" />
          Download for Mac
        </a>
        <a :href="SITE.github" class="btn btn-text w-full sm:w-auto" target="_blank" rel="noopener noreferrer">
          View on GitHub
        </a>
      </div>
      <p
        class="reveal d4 text-[0.82rem] font-medium tracking-[-0.01em] text-[color-mix(in_srgb,var(--muted)_78%,transparent)]"
      >
        Free · {{ SITE.version }} · macOS 26+ · Apple Silicon · MIT
      </p>

      <!-- Product proof starts as a complete static composition and gains motion on desktop. -->
      <MacBookDemo />
    </div>
  </header>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
