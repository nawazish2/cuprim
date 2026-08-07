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
              <span class="relative flex items-center" title="Cuprim">
                <svg class="absolute -inset-[3px]" viewBox="0 0 22 22" aria-hidden="true">
                  <circle cx="11" cy="11" r="9" fill="none" stroke="rgba(255,255,255,.22)" stroke-width="2" />
                  <circle
                    cx="11"
                    cy="11"
                    r="9"
                    fill="none"
                    stroke="#88c0ff"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-dasharray="56.5"
                    stroke-dashoffset="18.1"
                    transform="rotate(-90 11 11)"
                  />
                </svg>
                <CupLogo :size="14" class="relative !rounded-[4px]" />
              </span>
              <span class="font-semibold tracking-wide">{{ clock }}</span>
            </div>
          </div>

          <div
            class="animate-pop-in absolute right-3 top-10 z-[6] w-[min(308px,calc(100%-24px))] overflow-hidden rounded-[14px] border border-white/15 bg-[rgba(28,28,30,0.88)] shadow-2xl backdrop-blur-xl sm:right-16"
            role="dialog"
            aria-label="Cuprim status menu"
          >
            <div class="flex items-center gap-2 border-b border-white/10 px-3.5 py-3">
              <CupLogo :size="17" class="!rounded-[5px]" />
              <span class="text-[13px] font-bold text-white">Cuprim</span>
              <span class="rounded-full bg-white/10 px-2 py-0.5 font-mono text-[10px] text-white/70">
                {{ SITE.version }}
              </span>
            </div>

            <div
              v-for="p in PROVIDERS"
              :key="p.name"
              class="flex flex-col gap-1.5 border-t border-white/5 px-3.5 py-3 first:border-t-0"
            >
              <div class="flex items-center gap-2 text-[12.5px] text-white/90">
                <span class="size-2 shrink-0 rounded-full" :style="{ background: p.color }" />
                <span class="font-semibold">{{ p.name }}</span>
                <span class="text-[11px] text-white/45">{{ p.plan }}</span>
                <span class="ml-auto font-mono text-[11.5px] font-semibold text-[#9ecbff]">
                  {{ animated ? p.pct : 0 }}%
                </span>
              </div>
              <div class="h-[5px] overflow-hidden rounded-full bg-white/10">
                <div
                  class="h-full rounded-full transition-[width] duration-[1400ms] ease-out"
                  :style="{
                    width: animated ? `${p.pct}%` : '0%',
                    background: `linear-gradient(90deg, ${p.color}, #88c0ff)`,
                  }"
                />
              </div>
              <div class="font-mono text-[10.5px] text-white/45">
                resets in <b class="font-medium text-white/80">{{ p.reset }}</b>
              </div>
            </div>
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
      One icon at the rim of your screen. Zero tabs open to check a number.
    </p>
  </section>
</template>

<script setup lang="ts">
import { PROVIDERS, SITE } from "~/utils/site"

const macWrap = ref<HTMLElement | null>(null)
const animated = ref(false)
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
let io: IntersectionObserver | undefined

onMounted(() => {
  tickClock()
  clockTimer = setInterval(tickClock, 1000)

  if (macWrap.value) {
    io = new IntersectionObserver(
      (entries) => {
        for (const en of entries) {
          if (en.isIntersecting) {
            animated.value = true
            io?.unobserve(en.target)
          }
        }
      },
      { threshold: 0.35 },
    )
    io.observe(macWrap.value)
  }

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
  io?.disconnect()
})
</script>
