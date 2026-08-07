<template>
  <svg :width="size" :height="size" viewBox="0 0 32 32" aria-hidden="true">
    <path
      d="M8 12h13v7.5A6.5 6.5 0 0 1 14.5 26h-1A6.5 6.5 0 0 1 7 19.5V12Z"
      fill="currentColor"
      opacity="0.9"
    />
    <path
      d="M21 13.5h1.6a3.1 3.1 0 1 1 0 6.2H20.4"
      stroke="currentColor"
      stroke-width="2"
      fill="none"
    />
    <rect x="6" y="8.6" width="16" height="3.2" rx="1.6" fill="#f4b076" />
  </svg>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
  }>(),
  { size: 26 },
)
</script>
