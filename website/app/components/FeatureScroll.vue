<template>
  <section id="features" class="section">
    <div class="wrap">
      <div class="reveal section-eyebrow">What you get</div>
      <h2 class="reveal section-title">At the edge of the screen.</h2>
      <p class="reveal section-lead mt-3">
        No browser tab for quotas. Menu for glance, panel for detail.
      </p>

      <ul class="feature-grid reveal mt-10 sm:mt-14" role="list">
        <li v-for="f in features" :key="f.label" class="feature-cell">
          <span class="feature-icon" aria-hidden="true">
            <FeatureGlyph :name="f.icon" />
          </span>
          <span class="feature-label">{{ f.label }}</span>
        </li>
      </ul>
    </div>
  </section>
</template>

<script setup lang="ts">
const features = [
  { icon: "menu", label: "Lives in Menu Bar" },
  { icon: "gauge", label: "Status at a Glance" },
  { icon: "panel", label: "Dashboard Detail" },
  { icon: "providers", label: "Claude · Codex · Cursor · Grok" },
  { icon: "lock", label: "Local Only" },
  { icon: "shield", label: "No Telemetry" },
  { icon: "refresh", label: "One-Click Refresh" },
  { icon: "swift", label: "Native Swift App" },
  { icon: "free", label: "Free · MIT Forever" },
  { icon: "chip", label: "Apple Silicon" },
] as const
</script>

<style scoped>
.feature-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
  list-style: none;
  margin: 0 auto;
  max-width: 920px;
  padding: 0;
}

@media (min-width: 640px) {
  .feature-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 10px;
  }
}

@media (min-width: 900px) {
  .feature-grid {
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 12px;
  }
}

.feature-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  min-height: 112px;
  padding: 18px 10px 16px;
  border-radius: 16px;
  text-align: center;
  transition:
    background 0.2s ease,
    box-shadow 0.2s ease,
    transform 0.15s ease;
}

.feature-cell:hover {
  background: color-mix(in srgb, var(--surface) 72%, transparent);
  box-shadow:
    0 1px 0 color-mix(in srgb, #fff 70%, transparent) inset,
    0 8px 24px -16px rgba(24, 27, 23, 0.28);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.feature-icon {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  color: var(--ink);
}

.feature-label {
  max-width: 14ch;
  font-size: 0.92rem;
  font-weight: 600;
  letter-spacing: -0.022em;
  line-height: 1.25;
  color: var(--ink);
}

@media (prefers-reduced-motion: reduce) {
  .feature-cell {
    transition: none;
  }
}
</style>
