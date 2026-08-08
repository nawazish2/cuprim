<template>
  <!-- Monochrome gauge — matches Cuprim menu-bar glyph (SF-style ring + needle). -->
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 32 32"
    fill="none"
    aria-hidden="true"
    :class="className"
  >
    <circle
      cx="16"
      cy="16"
      r="11.5"
      :stroke="stroke"
      stroke-width="2.75"
      fill="none"
    />
    <circle cx="8.05" cy="21" r="1.15" :fill="stroke" />
    <circle cx="6.55" cy="14.2" r="1.15" :fill="stroke" />
    <circle cx="9" cy="8.2" r="1.15" :fill="stroke" />
    <circle cx="16" cy="5.65" r="1.15" :fill="stroke" />
    <circle cx="23" cy="8.2" r="1.15" :fill="stroke" />
    <circle cx="25.45" cy="14.2" r="1.15" :fill="stroke" />
    <circle cx="23.95" cy="21" r="1.15" :fill="stroke" />
    <circle cx="16" cy="16" r="2.4" :fill="stroke" />
    <path
      d="M16 16 L23.2 10.4"
      :stroke="stroke"
      stroke-width="2.6"
      stroke-linecap="round"
    />
  </svg>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: number | string
    /** Template ink for light/dark surfaces. */
    stroke?: string
    className?: string
  }>(),
  {
    size: 18,
    stroke: "currentColor",
    className: "",
  },
)
</script>
