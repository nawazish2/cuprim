<template>
  <header class="hero relative overflow-x-clip pb-10 pt-[88px] sm:pb-14 sm:pt-[108px]">
    <div
      class="pointer-events-none absolute inset-x-0 top-0 z-0 h-[420px]"
      aria-hidden="true"
      style="
        background:
          radial-gradient(580px 300px at 78% 0%, #0073eb12, transparent 68%),
          radial-gradient(480px 280px at 8% 10%, #181b1708, transparent 65%);
      "
    />
    <div class="wrap relative z-[1]">
      <div class="hero-grid">
        <div class="hero-copy">
          <CupLogo :size="56" class="mb-5 rounded-[14px] shadow-[0_14px_40px_-22px_rgba(24,27,23,0.5)]" />
          <h1 class="hero-title">
            Know which AI tool<br />
            runs out next
          </h1>
          <p class="hero-lead">
            Claude, Codex, Cursor, Grok, and Antigravity — live in the Mac menu bar. Local only. No telemetry.
          </p>
          <div class="hero-actions">
            <a :href="SITE.releasesLatest" class="btn btn-lg" target="_blank" rel="noopener noreferrer">
              <AppleMark class="size-[15px] shrink-0 opacity-95" />
              Download Cuprim
            </a>
            <a :href="SITE.github" class="btn btn-text" target="_blank" rel="noopener noreferrer">
              GitHub
              <span class="sr-only"> (opens in a new tab)</span>
            </a>
          </div>
          <p class="hero-meta">Free · Apple Silicon · macOS 26+ · MIT</p>
        </div>
        <div class="hero-visual">
          <MacBookDemo />
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"
</script>

<style scoped>
.hero-grid {
  display: grid;
  gap: 28px;
  align-items: center;
}

.hero-title {
  margin: 0 0 14px;
  max-width: 16ch;
  font-size: clamp(2.15rem, 5vw, 3.6rem);
  font-weight: 600;
  letter-spacing: -0.035em;
  line-height: 1.04;
}

.hero-lead {
  margin: 0 0 22px;
  max-width: 38ch;
  font-size: clamp(1.02rem, 1.8vw, 1.18rem);
  line-height: 1.4;
  color: var(--muted);
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 12px;
}

.hero-meta {
  margin: 0;
  font-size: 0.82rem;
  font-weight: 500;
  color: color-mix(in srgb, var(--muted) 78%, transparent);
}

@media (min-width: 900px) {
  .hero-grid {
    grid-template-columns: minmax(0, 0.92fr) minmax(0, 1.08fr);
    gap: 36px;
  }
}
</style>
