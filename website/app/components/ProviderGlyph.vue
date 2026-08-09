<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 16 16"
    fill="none"
    aria-hidden="true"
    class="shrink-0 text-white/85"
  >
    <!-- Claude: spark / asterisk -->
    <g v-if="name === 'Claude'" stroke="currentColor" stroke-width="1.3" stroke-linecap="round">
      <path d="M8 2.2v11.6M3.5 4.2l9 7.6M3.5 11.8l9-7.6" />
    </g>
    <!-- Codex: open hex / loop -->
    <g v-else-if="name === 'Codex'" fill="currentColor">
      <path
        d="M8 1.6 13.2 4.6v6.8L8 14.4 2.8 11.4V4.6L8 1.6Zm0 1.7L4.2 5.1v5.8L8 12.7l3.8-1.8V5.1L8 3.3Z"
      />
    </g>
    <!-- Cursor: cube -->
    <g v-else-if="name === 'Cursor'" stroke="currentColor" stroke-width="1.2" fill="none" stroke-linejoin="round">
      <path d="M8 2.2 13 5v6L8 13.8 3 11V5L8 2.2Z" />
      <path d="M3 5l5 2.8L13 5M8 7.8v6" />
    </g>
    <!-- Grok: slash circle -->
    <g v-else stroke="currentColor" stroke-width="1.3" fill="none">
      <circle cx="8" cy="8" r="5.4" />
      <path d="M4.5 11.5 11.5 4.5" stroke-linecap="round" />
    </g>
  </svg>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    name: "Claude" | "Codex" | "Cursor" | "Grok"
    size?: number | string
  }>(),
  { size: 16 },
)
</script>
