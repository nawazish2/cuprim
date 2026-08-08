<template>
  <section class="wrap pb-10 pt-2" aria-label="Cuprim running in the macOS menu bar" style="perspective: 1400px">
    <div
      ref="macWrap"
      class="mac-wrap mx-auto max-w-[920px] transition-transform duration-300 ease-out"
      style="transform-style: preserve-3d"
    >
      <div
        class="rounded-[22px] border border-[var(--line)] bg-[#111] p-2 shadow-[0_40px_90px_-40px_rgba(24,27,23,0.55)]"
      >
        <div
          class="relative aspect-[16/10] overflow-hidden rounded-[16px]"
          style="
            background:
              radial-gradient(ellipse at 30% 20%, #1a2740 0%, #0c1018 45%, #080a0e 75%),
              linear-gradient(160deg, #121820, #080a0e 60%);
          "
        >
          <!-- Menu bar -->
          <div
            class="absolute inset-x-0 top-0 z-[5] flex h-8 items-center justify-between bg-black/40 px-3.5 text-[12.5px] font-medium text-white/90 backdrop-blur-md"
          >
            <div class="flex items-center gap-3.5">
              <span class="font-bold"></span>
              <span class="font-bold">Finder</span>
              <span class="hidden text-white/70 sm:inline">File</span>
              <span class="hidden text-white/70 sm:inline">Edit</span>
            </div>
            <div class="flex items-center gap-3">
              <span
                class="flex items-center justify-center rounded-[5px] bg-white/15 px-1 py-0.5 text-white"
                title="Cuprim"
              >
                <MenuGauge :size="14" stroke="#fff" />
              </span>
              <span class="font-semibold tracking-wide">{{ clock }}</span>
            </div>
          </div>

          <!-- Native-style status menu (Usage · title + subtitle · actions) -->
          <div
            class="animate-pop-in absolute right-3 top-10 z-[6] w-[min(248px,calc(100%-24px))] overflow-hidden rounded-[12px] border border-white/12 bg-[rgba(36,36,38,0.92)] shadow-2xl backdrop-blur-xl sm:right-14"
            role="dialog"
            aria-label="Cuprim status menu"
          >
            <div class="px-3.5 pb-1 pt-2.5 text-[11px] font-medium text-white/45">Usage</div>

            <ul class="pb-1">
              <li
                v-for="p in MENU_PROVIDERS"
                :key="p.name"
                class="flex items-start gap-2.5 px-3.5 py-[7px]"
              >
                <span
                  class="mt-0.5 flex size-4 shrink-0 items-center justify-center rounded-[4px] bg-white/10 text-[10px] font-bold text-white/80"
                  aria-hidden="true"
                >{{ p.name.charAt(0) }}</span>
                <span class="min-w-0 flex-1 leading-tight">
                  <span class="block text-[13px] font-semibold text-white/95">
                    {{ p.name }} · {{ p.plan }}
                  </span>
                  <span class="mt-0.5 block text-[11.5px] text-white/50">
                    {{ p.status }}
                  </span>
                </span>
              </li>
            </ul>

            <div class="mx-2 h-px bg-white/10" />

            <ul class="py-1 text-[13px] text-white/90">
              <li class="flex items-center justify-between px-3.5 py-[6px]">
                <span>Show Cuprim</span>
              </li>
              <li class="flex items-center justify-between px-3.5 py-[6px]">
                <span>Refresh</span>
                <span class="font-mono text-[11px] text-white/40">⌘R</span>
              </li>
              <li class="flex items-center justify-between px-3.5 py-[6px]">
                <span>Settings…</span>
                <span class="font-mono text-[11px] text-white/40">⌘,</span>
              </li>
            </ul>

            <div class="mx-2 h-px bg-white/10" />

            <ul class="py-1 text-[13px] text-white/90">
              <li class="px-3.5 py-[6px]">Check for Updates…</li>
            </ul>

            <div class="mx-2 h-px bg-white/10" />

            <ul class="pb-1.5 pt-1 text-[13px] text-white/90">
              <li class="flex items-center justify-between px-3.5 py-[6px]">
                <span>Quit Cuprim</span>
                <span class="font-mono text-[11px] text-white/40">⌘Q</span>
              </li>
            </ul>
          </div>

          <div
            class="absolute bottom-3 left-1/2 z-[4] flex -translate-x-1/2 items-center gap-2 rounded-[18px] border border-white/10 bg-black/40 px-3 py-2 backdrop-blur-md"
            aria-hidden="true"
          >
            <i
              v-for="(c, i) in dock"
              :key="i"
              class="block size-[30px] rounded-[9px] max-[560px]:size-6"
              :style="{ background: c }"
            />
          </div>
        </div>
      </div>
    </div>
    <p class="mt-6 text-center font-mono text-[0.82rem] text-[var(--muted)]">
      One glance in the menu bar. Details open when you need them.
    </p>
  </section>
</template>

<script setup lang="ts">
import { MENU_PROVIDERS } from "~/utils/site"

const macWrap = ref<HTMLElement | null>(null)
const clock = ref("")
const dock = [
  "linear-gradient(150deg,#88c0ff,#1d4f8a)",
  "linear-gradient(150deg,#5aa7e8,#1d4f8a)",
  "linear-gradient(150deg,#8fce6f,#2f6b3a)",
  "linear-gradient(150deg,#e8b34b,#8a5a1d)",
  "linear-gradient(150deg,#7a7a7a,#3a3a3a)",
]

function tickClock() {
  const d = new Date()
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  const mons = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  let h = d.getHours()
  const ap = h >= 12 ? "PM" : "AM"
  let h12 = h % 12
  if (h12 === 0) h12 = 12
  const m = d.getMinutes().toString().padStart(2, "0")
  clock.value = `${days[d.getDay()]} ${mons[d.getMonth()]} ${d.getDate()}  ${h12}:${m} ${ap}`
}

let clockTimer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  tickClock()
  clockTimer = setInterval(tickClock, 1000)

  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  const fine = window.matchMedia("(pointer: fine)").matches
  if (!reduce && fine && macWrap.value) {
    const el = macWrap.value
    const onMove = (e: PointerEvent) => {
      const r = el.getBoundingClientRect()
      const px = (e.clientX - r.left) / r.width - 0.5
      const py = (e.clientY - r.top) / r.height - 0.5
      el.style.transform = `rotateY(${(px * 4).toFixed(2)}deg) rotateX(${(-py * 3).toFixed(2)}deg)`
    }
    const onLeave = () => {
      el.style.transform = "rotateY(0deg) rotateX(0deg)"
    }
    el.addEventListener("pointermove", onMove)
    el.addEventListener("pointerleave", onLeave)
    onUnmounted(() => {
      el.removeEventListener("pointermove", onMove)
      el.removeEventListener("pointerleave", onLeave)
    })
  }
})

onUnmounted(() => {
  if (clockTimer) clearInterval(clockTimer)
})
</script>
