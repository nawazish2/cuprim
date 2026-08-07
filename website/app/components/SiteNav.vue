<template>
  <header
    id="nav"
    class="fixed inset-x-0 top-0 z-50 border-b transition-[background,border-color,backdrop-filter] duration-300"
    :class="
      scrolled
        ? 'border-[var(--line)] bg-[rgba(10,9,8,0.72)] backdrop-blur-[14px]'
        : 'border-transparent bg-transparent'
    "
  >
    <div class="mx-auto flex h-[68px] max-w-[1120px] items-center gap-7 px-6">
      <a href="#top" class="flex items-center gap-2.5 text-lg font-extrabold tracking-tight" aria-label="Cuprim home">
        <CupLogo class="text-[var(--copper)]" :size="26" />
        Cuprim<span class="text-[var(--copper)]">.</span>
      </a>

      <nav class="ml-3.5 hidden items-center gap-6 text-sm font-medium text-[var(--mut)] md:flex" aria-label="Primary">
        <a href="#features" class="transition hover:text-[var(--text)]">Features</a>
        <a href="#trust" class="transition hover:text-[var(--text)]">Trust</a>
        <a href="#faq" class="transition hover:text-[var(--text)]">FAQ</a>
      </nav>

      <div class="ml-auto hidden items-center gap-3.5 md:flex">
        <a
          :href="SITE.github"
          class="flex items-center gap-1.5 text-sm font-semibold text-[var(--mut)] transition hover:text-[var(--text)]"
          target="_blank"
          rel="noopener noreferrer"
        >
          <span aria-hidden="true">⌘</span>
          nawazish2/cuprim
        </a>
        <a :href="SITE.releasesLatest" class="btn-primary" target="_blank" rel="noopener noreferrer">
          Download for Mac
        </a>
      </div>

      <button
        type="button"
        class="ml-auto flex size-10 items-center justify-center rounded-[10px] border border-[var(--line2)] text-[var(--text)] md:hidden"
        :aria-expanded="menuOpen"
        aria-label="Open menu"
        @click="menuOpen = !menuOpen"
      >
        <span class="text-lg leading-none">☰</span>
      </button>
    </div>

    <div
      v-show="menuOpen"
      class="border-b border-[var(--line)] bg-[rgba(10,9,8,0.95)] px-6 py-3 backdrop-blur-md md:hidden"
    >
      <a href="#features" class="block border-b border-[var(--line)] py-3 text-base font-semibold text-[var(--mut)]" @click="menuOpen = false">Features</a>
      <a href="#trust" class="block border-b border-[var(--line)] py-3 text-base font-semibold text-[var(--mut)]" @click="menuOpen = false">Why you can trust it</a>
      <a href="#faq" class="block border-b border-[var(--line)] py-3 text-base font-semibold text-[var(--mut)]" @click="menuOpen = false">FAQ</a>
      <a :href="SITE.github" class="block border-b border-[var(--line)] py-3 text-base font-semibold text-[var(--mut)]" target="_blank" rel="noopener noreferrer">GitHub ↗</a>
      <a :href="SITE.releasesLatest" class="block py-3 text-base font-semibold text-[var(--copper2)]" target="_blank" rel="noopener noreferrer">Download for Mac ↓</a>
    </div>
  </header>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

const scrolled = ref(false)
const menuOpen = ref(false)

function onScroll() {
  scrolled.value = window.scrollY > 10
}

onMounted(() => {
  onScroll()
  window.addEventListener("scroll", onScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener("scroll", onScroll)
})
</script>
