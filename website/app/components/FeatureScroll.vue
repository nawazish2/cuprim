<template>
  <section id="providers" class="section">
    <div class="wrap">
      <div class="section-eyebrow">Providers</div>
      <h2 class="section-title">Four tools. One glance.</h2>
      <p class="section-lead mt-3">
        Cuprim reads the sign-in already on this Mac. It never creates an account with us.
      </p>
      <ul class="provider-list mt-10" role="list">
        <li v-for="name in PROVIDERS" :key="name">{{ name }}</li>
      </ul>
    </div>
  </section>
</template>

<script setup lang="ts">
import { PROVIDERS } from "~/utils/site"
</script>

<style scoped>
.provider-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.provider-list li {
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 0.95rem;
  font-weight: 600;
  letter-spacing: -0.02em;
  background: color-mix(in srgb, var(--surface) 80%, transparent);
  border: 1px solid var(--line);
}
</style>
