<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 32 32"
    fill="none"
    stroke="currentColor"
    stroke-width="1.7"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <!-- Menu bar capsule -->
    <template v-if="name === 'menu'">
      <rect x="4" y="12" width="24" height="8" rx="4" />
      <path d="M8 14.5v3M11 14.5v3" />
    </template>

    <!-- Gauge / glance -->
    <template v-else-if="name === 'gauge'">
      <circle cx="16" cy="16" r="10" />
      <path d="M16 16l6-5" />
      <circle cx="16" cy="16" r="1.6" fill="currentColor" stroke="none" />
    </template>

    <!-- Dashboard panel -->
    <template v-else-if="name === 'panel'">
      <rect x="6" y="6" width="20" height="20" rx="4" />
      <path d="M10 13h12M10 17h8M10 21h10" />
    </template>

    <!-- Four providers -->
    <template v-else-if="name === 'providers'">
      <circle cx="11" cy="11" r="3.2" />
      <circle cx="21" cy="11" r="3.2" />
      <circle cx="11" cy="21" r="3.2" />
      <circle cx="21" cy="21" r="3.2" />
    </template>

    <!-- Local lock -->
    <template v-else-if="name === 'lock'">
      <rect x="9" y="14" width="14" height="11" rx="2.5" />
      <path d="M12 14v-2.5a4 4 0 0 1 8 0V14" />
    </template>

    <!-- Shield / no telemetry -->
    <template v-else-if="name === 'shield'">
      <path d="M16 5l9 4v7c0 5.2-3.6 9-9 11-5.4-2-9-5.8-9-11V9l9-4Z" />
      <path d="M12.5 16.2l2.4 2.4 4.6-4.8" />
    </template>

    <!-- Refresh -->
    <template v-else-if="name === 'refresh'">
      <path d="M7.5 16a8.5 8.5 0 0 1 14.4-6.1" />
      <path d="M24.5 16a8.5 8.5 0 0 1-14.4 6.1" />
      <path d="M22 6.8v4.2h-4.2M10 25.2v-4.2h4.2" />
    </template>

    <!-- Swift / quill -->
    <template v-else-if="name === 'swift'">
      <path d="M8 24c6-1 11-5 14-11 1.2-2.4 1.8-5 1.8-7.5-3.8.8-6.8 2.4-9 4.8C11.5 14 9.2 18.5 8 24Z" />
      <path d="M9.2 21.5c2.8-1.2 5.5-3.4 7.5-6" />
    </template>

    <!-- Free / gift mark -->
    <template v-else-if="name === 'free'">
      <rect x="6" y="13" width="20" height="13" rx="2.5" />
      <path d="M16 13v13M6 18.5h20" />
      <path d="M16 13c-2.2-3.5-5.5-3.8-6.5-1.8S11.5 15 16 13c2.2-3.5 5.5-3.8 6.5-1.8S20.5 15 16 13Z" />
    </template>

    <!-- Apple Silicon chip -->
    <template v-else-if="name === 'chip'">
      <rect x="9" y="9" width="14" height="14" rx="2.5" />
      <rect x="12.5" y="12.5" width="7" height="7" rx="1.2" />
      <path d="M12 6.5v2.5M16 6.5v2.5M20 6.5v2.5M12 23v2.5M16 23v2.5M20 23v2.5M6.5 12h2.5M6.5 16h2.5M6.5 20h2.5M23 12h2.5M23 16h2.5M23 20h2.5" />
    </template>

    <!-- Open source / code -->
    <template v-else-if="name === 'code'">
      <path d="M12 8l-6 8 6 8" />
      <path d="M20 8l6 8-6 8" />
      <path d="M17.5 7.5l-3 17" />
    </template>
  </svg>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    name:
      | "menu"
      | "gauge"
      | "panel"
      | "providers"
      | "lock"
      | "shield"
      | "refresh"
      | "swift"
      | "free"
      | "chip"
      | "code"
    size?: number | string
  }>(),
  { size: 36 },
)
</script>
