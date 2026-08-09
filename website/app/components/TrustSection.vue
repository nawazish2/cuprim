<template>
  <section id="trust" class="section">
    <div class="wrap">
      <div class="reveal section-eyebrow">Trust</div>
      <h2 class="reveal section-title">Built to earn its place.</h2>
      <p class="reveal section-lead mt-3">
        A menu-bar app should stay out of the way — and out of your data.
      </p>

      <div class="trust-grid reveal mt-10 sm:mt-14">
        <article v-for="c in cards" :key="c.title" class="trust-card">
          <div class="trust-icon" aria-hidden="true">
            <FeatureGlyph :name="c.icon" :size="32" />
          </div>
          <h3 class="trust-title">{{ c.title }}</h3>
          <p class="trust-body">
            {{ c.body }}
            <a
              v-if="c.link"
              :href="c.link"
              class="trust-link"
              target="_blank"
              rel="noopener noreferrer"
            >GitHub.</a>
          </p>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

const cards = [
  {
    icon: "code" as const,
    title: "Open source",
    body: "The code is public. Audit it, fork it, or read every network call yourself.",
    link: SITE.github,
  },
  {
    icon: "shield" as const,
    title: "Private by design",
    body: "No Cuprim account, no trackers, no analytics — on the app or this site. Credentials never leave your Mac.",
    link: "",
  },
  {
    icon: "free" as const,
    title: "Free, MIT forever",
    body: "No paywall and no trial clock. If that ever changes, it will be in the repo first.",
    link: "",
  },
]
</script>

<style scoped>
.trust-grid {
  display: grid;
  gap: 12px;
  margin-left: auto;
  margin-right: auto;
  max-width: 960px;
  grid-template-columns: 1fr;
}

@media (min-width: 768px) {
  .trust-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
  }
}

.trust-card {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  border-radius: 20px;
  padding: 24px 22px 26px;
  text-align: left;
  background:
    linear-gradient(
      165deg,
      color-mix(in srgb, #fff 62%, transparent) 0%,
      color-mix(in srgb, #fff 28%, transparent) 100%
    ),
    color-mix(in srgb, var(--paper) 35%, transparent);
  border: 1px solid color-mix(in srgb, #fff 70%, var(--line));
  box-shadow:
    0 1px 0 color-mix(in srgb, #fff 80%, transparent) inset,
    0 14px 36px -22px rgba(24, 27, 23, 0.32);
  backdrop-filter: blur(18px) saturate(1.35);
  -webkit-backdrop-filter: blur(18px) saturate(1.35);
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.trust-card::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  background: linear-gradient(
    125deg,
    color-mix(in srgb, #fff 42%, transparent) 0%,
    transparent 45%,
    color-mix(in srgb, #0073eb 6%, transparent) 100%
  );
  opacity: 0.85;
  z-index: 0;
}

.trust-card > * {
  position: relative;
  z-index: 1;
}

.trust-card:hover {
  transform: translateY(-2px);
  box-shadow:
    0 1px 0 color-mix(in srgb, #fff 85%, transparent) inset,
    0 18px 40px -20px rgba(24, 27, 23, 0.4);
}

.trust-icon {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  margin-bottom: 16px;
  border-radius: 14px;
  color: var(--ink);
  background: color-mix(in srgb, var(--surface) 55%, transparent);
  border: 1px solid color-mix(in srgb, #fff 60%, var(--line));
  box-shadow: 0 1px 0 color-mix(in srgb, #fff 65%, transparent) inset;
}

.trust-title {
  margin: 0 0 8px;
  font-size: 1.15rem;
  font-weight: 600;
  letter-spacing: -0.024em;
  color: var(--ink);
}

.trust-body {
  margin: 0;
  max-width: 32ch;
  font-size: 0.98rem;
  font-weight: 400;
  line-height: 1.45;
  color: var(--muted);
}

.trust-link {
  color: var(--accent-deep);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.trust-link:hover {
  color: var(--accent);
}

@media (prefers-reduced-motion: reduce) {
  .trust-card {
    transition: none;
  }

  .trust-card:hover {
    transform: none;
  }
}

@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .trust-card {
    background: color-mix(in srgb, var(--surface) 94%, var(--paper));
  }
}
</style>
