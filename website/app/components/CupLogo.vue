<template>
  <svg :width="size" :height="size" viewBox="0 0 32 32" aria-hidden="true">
    <rect width="32" height="32" rx="8" fill="#000" />
    <!-- Cup body -->
    <path
      d="M9.2 12.2h10.4v9.2c0 3.1-2.5 5.6-5.6 5.6h0c-3.1 0-5.6-2.5-5.6-5.6v-9.2Z"
      fill="#fff"
    />
    <!-- Handle -->
    <path
      d="M19.4 13.6c2.85 0 4.7 1.85 4.7 4.35S22.25 22.3 19.4 22.3"
      stroke="#fff"
      stroke-width="2.4"
      stroke-linecap="round"
      fill="none"
    />
    <!-- Lid -->
    <rect x="8" y="9.4" width="13" height="3.1" rx="1.55" fill="#0073eb" />
  </svg>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
  }>(),
  { size: 28 },
)
</script>
