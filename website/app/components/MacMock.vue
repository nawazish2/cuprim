<template>
  <section class="px-0 pb-8 pt-16" aria-label="Cuprim running in the macOS menu bar" style="perspective: 1600px">
    <div
      ref="macWrap"
      class="mac-wrap mx-auto max-w-[1020px] px-6 transition-transform duration-300 ease-out"
      style="transform-style: preserve-3d"
    >
      <div
        class="rounded-[26px] border border-white/10 bg-black p-2.5 shadow-[0_40px_90px_-30px_rgba(0,0,0,0.85),0_30px_120px_-20px_rgba(224,138,76,0.18)]"
      >
        <div
          class="relative aspect-[16/10] overflow-hidden rounded-[18px]"
          style="
            background:
              radial-gradient(ellipse at 30% 20%, #2a1c10 0%, #14100c 40%, #0a0908 70%),
              linear-gradient(160deg, #14100c, #0a0908 60%);
          "
        >
          <!-- Menu bar -->
          <div
            class="absolute inset-x-0 top-0 z-[5] flex h-8 items-center justify-between bg-[rgba(14,11,9,0.78)] px-3.5 text-[12.5px] font-medium text-[rgba(244,237,228,0.92)] backdrop-blur-md"
          >
            <div class="flex items-center gap-3.5">
              <span class="font-bold"></span>
              <span class="font-bold">Finder</span>
              <span class="hidden text-[rgba(244,237,228,0.72)] sm:inline">File</span>
              <span class="hidden text-[rgba(244,237,228,0.72)] sm:inline">Edit</span>
              <span class="hidden text-[rgba(244,237,228,0.72)] md:inline">View</span>
            </div>
            <div class="flex items-center gap-3">
              <span class="relative flex items-center text-white" title="Cuprim">
                <svg class="absolute -inset-[3px]" viewBox="0 0 22 22" aria-hidden="true">
                  <circle cx="11" cy="11" r="9" fill="none" stroke="rgba(255,255,255,.22)" stroke-width="2" />
                  <circle
                    cx="11"
                    cy="11"
                    r="9"
                    fill="none"
                    stroke="var(--copper2)"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-dasharray="56.5"
                    stroke-dashoffset="18.1"
                    transform="rotate(-90 11 11)"
                  />
                </svg>
                <CupLogo :size="14" class="relative text-white" />
              </span>
              <span class="font-semibold tracking-wide">{{ clock }}</span>
            </div>
          </div>

          <!-- Status popover -->
          <div
            class="animate-pop-in absolute right-3 top-10 z-[6] w-[min(308px,calc(100%-24px))] overflow-hidden rounded-[14px] border border-white/15 bg-[rgba(24,20,17,0.86)] shadow-[0_24px_60px_-12px_rgba(0,0,0,0.8)] backdrop-blur-xl sm:right-[88px]"
            role="dialog"
            aria-label="Cuprim status menu"
          >
            <div class="flex items-center gap-2 border-b border-white/10 px-3.5 py-3">
              <CupLogo :size="17" class="text-[var(--copper2)]" />
              <span class="text-[13px] font-bold">Cuprim</span>
              <span
                class="rounded-full border border-[rgba(224,138,76,0.3)] bg-[rgba(224,138,76,0.14)] px-2 py-0.5 font-mono text-[10px] text-[var(--copper2)]"
              >
                {{ SITE.version }}
              </span>
            </div>

            <div
              v-for="p in PROVIDERS"
              :key="p.name"
              class="flex flex-col gap-1.5 border-t border-white/5 px-3.5 py-3 first:border-t-0"
            >
              <div class="flex items-center gap-2 text-[12.5px]">
                <span class="size-2 shrink-0 rounded-full" :style="{ background: p.color }" />
                <span class="font-semibold">{{ p.name }}</span>
                <span class="text-[11px] text-[rgba(244,237,228,0.5)]">{{ p.plan }}</span>
                <span class="ml-auto font-mono text-[11.5px] font-semibold text-[var(--copper2)]">
                  {{ animated ? p.pct : 0 }}%
                </span>
              </div>
              <div class="h-[5px] overflow-hidden rounded-full bg-white/10">
                <div
                  class="h-full rounded-full transition-[width] duration-[1400ms] ease-out"
                  :style="{
                    width: animated ? `${p.pct}%` : '0%',
                    background: 'linear-gradient(90deg, var(--copper-deep), var(--copper2))',
                  }"
                />
              </div>
              <div class="font-mono text-[10.5px] text-[rgba(244,237,228,0.5)]">
                resets in <b class="font-medium text-[rgba(244,237,228,0.85)]">{{ p.reset }}</b>
              </div>
            </div>

            <div
              class="flex items-center gap-2.5 border-t border-white/10 bg-black/20 px-3.5 py-2.5 text-[11px] text-[rgba(244,237,228,0.6)]"
            >
              <span>Next glance · <b class="font-semibold text-[var(--copper2)]">menu bar</b></span>
              <span class="ml-auto flex gap-1.5">
                <span class="rounded-md border border-white/10 bg-white/5 px-2.5 py-1 font-semibold">Settings</span>
                <span class="rounded-md border border-white/10 bg-white/5 px-2.5 py-1 font-semibold">Quit</span>
              </span>
            </div>
          </div>

          <!-- Dock -->
          <div
            class="absolute bottom-3 left-1/2 z-[4] flex -translate-x-1/2 items-center gap-2 rounded-[18px] border border-white/10 bg-[rgba(20,16,13,0.5)] px-3 py-2 backdrop-blur-md"
            aria-hidden="true"
          >
            <i
              v-for="(c, i) in dock"
              :key="i"
              class="block size-[34px] rounded-[9px] max-[560px]:size-[26px]"
              :style="{ background: c }"
            />
          </div>
        </div>
      </div>
    </div>
    <p class="mt-6 text-center font-mono text-xs text-[var(--dim)]">
      One icon at the <b class="font-medium text-[var(--copper)]">rim</b> of your screen. Zero tabs open to check a number.
    </p>
  </section>
</template>

<script setup lang="ts">
import { PROVIDERS, SITE } from "~/utils/site"

const macWrap = ref<HTMLElement | null>(null)
const animated = ref(false)
const clock = ref("")
const dock = [
  "linear-gradient(150deg,#f4b076,#8a4a20)",
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
      el.style.transform = `rotateY(${(px * 5).toFixed(2)}deg) rotateX(${(-py * 4).toFixed(2)}deg)`
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
