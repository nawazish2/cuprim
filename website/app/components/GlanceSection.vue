<template>
  <section id="glance" class="section section--product">
    <div class="wrap glance-grid">
      <div class="reveal">
        <div class="section-eyebrow">Menu bar</div>
        <h2 class="section-title section-title--left">Click the gauge. The dashboard opens.</h2>
        <p class="section-lead section-lead--left mt-3">
          The menu bar stays a glance — remaining percent, not a second usage page. Detail lives in the glass panel: meters, reset times, and what to do if a session expired.
        </p>
      </div>
      <img
        class="glance-shot reveal d2"
        src="/cuprim-glance.webp"
        width="1280"
        height="720"
        alt="The Cuprim menu-bar gauge and the open dashboard panel over a Mac desktop"
        loading="lazy"
        decoding="async"
      >
    </div>
  </section>
</template>

<style scoped>
.glance-grid {
  display: grid;
  gap: 32px;
}

.glance-shot {
  display: block;
  width: 100%;
  height: auto;
  border-radius: 16px;
  border: 1px solid var(--line-soft);
  box-shadow: 0 24px 48px -20px rgb(0 0 0 / 22%);
}

@media (min-width: 900px) {
  .glance-grid {
    grid-template-columns: minmax(0, 0.85fr) minmax(0, 1.15fr);
    align-items: center;
    gap: 48px;
  }
}
</style>
