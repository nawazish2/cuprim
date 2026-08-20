<template>
  <section id="providers" class="section section--product">
    <div class="wrap providers-grid">
      <img
        class="providers-shot reveal"
        src="/cuprim-providers.webp"
        width="600"
        height="500"
        alt="The Cuprim dashboard's provider tab bar and a Cursor usage card"
        loading="lazy"
        decoding="async"
      >
      <div class="reveal d2">
        <div class="section-eyebrow">Providers</div>
        <h2 class="section-title section-title--left">Four tools. One glance.</h2>
        <p class="section-lead section-lead--left mt-3">
          Cuprim reads the sign-in already on this Mac. It never creates an account with us.
        </p>
        <ol class="statement-list providers-list" aria-label="Supported providers">
          <li v-for="provider in PROVIDER_DETAILS" :key="provider.name" class="statement-row">
            <div class="statement-title">{{ provider.name }}</div>
            <div class="statement-body">{{ provider.detail }}</div>
          </li>
        </ol>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const PROVIDER_DETAILS = [
  { name: "Claude", detail: "Session and weekly limits, from Claude Code or Desktop." },
  { name: "Codex", detail: "Session and weekly limits from the Codex CLI." },
  { name: "Cursor", detail: "Auto, API, and total usage in one card." },
  { name: "Grok", detail: "Billing-period credit usage." },
]
</script>

<style scoped>
.providers-grid {
  display: grid;
  gap: 32px;
}

.providers-list {
  margin-top: 28px;
  max-width: none;
}

.providers-shot {
  display: block;
  width: 100%;
  height: auto;
  border-radius: 16px;
  border: 1px solid var(--line-soft);
  box-shadow: 0 24px 48px -20px rgb(0 0 0 / 22%);
  mask-image: linear-gradient(to bottom, black 88%, transparent 100%);
}

@media (min-width: 900px) {
  .providers-grid {
    grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
    align-items: center;
    gap: 48px;
  }
}
</style>
