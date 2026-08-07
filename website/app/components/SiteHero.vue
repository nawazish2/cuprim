<template>
  <section class="relative px-6 pb-10 pt-[170px] text-center max-md:pt-[140px]">
    <div class="mx-auto max-w-[1120px]">
      <div
        class="reveal in mb-6 inline-flex items-center gap-2 rounded-full border border-[rgba(224,138,76,0.28)] bg-[rgba(224,138,76,0.08)] px-4 py-1.5 font-mono text-[11.5px] font-medium uppercase tracking-[0.16em] text-[var(--copper)]"
      >
        <i class="animate-pulse-dot size-1.5 rounded-full bg-[var(--copper)] shadow-[0_0_10px_var(--copper)]" />
        Free · Open source · macOS menu bar
      </div>

      <h1
        class="reveal in d1 text-[clamp(44px,7.2vw,84px)] font-extrabold leading-[1.02] tracking-[-0.035em]"
      >
        Every AI quota,<br />
        right at the <span class="font-serif-accent pr-[0.06em] tracking-[-0.01em]">rim</span>.
      </h1>

      <p class="reveal in d2 mx-auto mt-6 max-w-[640px] text-[clamp(16px,1.6vw,18.5px)] text-[var(--mut)]">
        Cuprim is a tiny, open-source menu-bar app for macOS that watches your
        <strong class="font-semibold text-[var(--text)]">Claude, Codex, Cursor, and Grok</strong>
        usage — remaining quota and resets — so you never burn a limit by surprise.
      </p>

      <div class="reveal in d3 mt-9 flex flex-wrap justify-center gap-3.5 max-[560px]:flex-col">
        <a :href="SITE.releasesLatest" class="btn-primary btn-lg max-[560px]:w-full max-[560px]:justify-center" target="_blank" rel="noopener noreferrer">
          Download for Mac
        </a>
        <a :href="SITE.github" class="btn-ghost btn-lg max-[560px]:w-full max-[560px]:justify-center" target="_blank" rel="noopener noreferrer">
          Star on GitHub
        </a>
      </div>

      <p class="reveal in d3 mt-5 font-mono text-xs tracking-wide text-[var(--dim)]">
        <b class="font-medium text-[var(--mut)]">{{ SITE.version }}</b>
        <span class="mx-1.5 text-[var(--line2)]">·</span>macOS 26+
        <span class="mx-1.5 text-[var(--line2)]">·</span>Apple Silicon
        <span class="mx-1.5 text-[var(--line2)]">·</span>MIT License
      </p>
    </div>
  </section>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>
