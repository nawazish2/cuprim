<template>
  <section
    class="mac-mock"
    :class="embedded ? 'mac-mock--embedded' : 'wrap pb-8 pt-2'"
    aria-label="Cuprim on macOS"
  >
    <div class="mac-wrap mx-auto max-w-[920px]">
      <div class="mac-bezel">
        <div class="mac-screen">
          <!-- Atmosphere / wallpaper -->
          <div class="mac-wallpaper" aria-hidden="true">
            <div class="mac-wallpaper__glow mac-wallpaper__glow--a" />
            <div class="mac-wallpaper__glow mac-wallpaper__glow--b" />
            <div class="mac-wallpaper__glow mac-wallpaper__glow--c" />
            <div class="mac-wallpaper__window" />
            <div class="mac-wallpaper__vignette" />
            <div class="mac-wallpaper__noise" />
          </div>

          <!-- Menu bar -->
          <div class="mac-menubar">
            <div class="flex items-center gap-3.5">
              <span class="font-semibold"></span>
              <span class="font-semibold">Finder</span>
              <span class="hidden text-white/55 sm:inline">File</span>
              <span class="hidden text-white/55 sm:inline">Edit</span>
            </div>
            <div class="flex items-center gap-2.5">
              <span
                class="mac-gauge"
                :class="surface === 'menu' ? 'mac-gauge--active' : ''"
                title="Cuprim"
              >
                <MenuGauge :size="13" stroke="#fff" />
              </span>
              <span class="tabular-nums tracking-wide text-white/90">{{ clock }}</span>
            </div>
          </div>

          <!-- Status menu (glance) -->
          <Transition name="mac-surface">
            <div
              v-if="surface === 'menu'"
              key="menu"
              class="mac-glass mac-menu"
              role="dialog"
              aria-label="Cuprim status menu"
            >
              <div class="px-3 pb-0.5 pt-2.5 text-[11px] font-medium text-white/42">Usage</div>

              <ul>
                <li
                  v-for="p in MENU_PROVIDERS"
                  :key="p.name"
                  class="flex items-start gap-2.5 px-3 py-[6px]"
                >
                  <ProviderGlyph :name="p.name" :size="15" class="mt-[2px]" />
                  <span class="min-w-0 flex-1 leading-snug">
                    <span class="block text-[12.5px] font-semibold tracking-[-0.01em] text-white/[0.96]">
                      {{ p.name }} · {{ p.plan }}
                    </span>
                    <span class="mt-0.5 block text-[11px] text-white/48">
                      {{ p.status }}
                    </span>
                  </span>
                </li>
              </ul>

              <div class="mac-divider" />

              <ul class="py-0.5 text-[12.5px] text-white/90">
                <li class="flex items-center justify-between px-3 py-[5px]">
                  <span>Show Cuprim</span>
                </li>
                <li class="flex items-center justify-between px-3 py-[5px]">
                  <span>Refresh</span>
                  <span class="text-[11px] text-white/38">⌘R</span>
                </li>
                <li class="flex items-center justify-between px-3 py-[5px]">
                  <span>Settings…</span>
                  <span class="text-[11px] text-white/38">⌘,</span>
                </li>
              </ul>

              <div class="mac-divider" />

              <ul class="pb-1.5 pt-0.5 text-[12.5px] text-white/90">
                <li class="flex items-center justify-between px-3 py-[5px]">
                  <span>Quit Cuprim</span>
                  <span class="text-[11px] text-white/38">⌘Q</span>
                </li>
              </ul>
            </div>
          </Transition>

          <!-- Glass dashboard panel -->
          <Transition name="mac-surface">
            <div
              v-if="surface === 'panel'"
              key="panel"
              class="mac-glass mac-panel"
              role="dialog"
              aria-label="Cuprim dashboard"
            >
              <div class="flex items-center justify-between px-3.5 pb-2 pt-3">
                <div class="flex items-center gap-2">
                  <CupLogo :size="18" class="!rounded-[5px]" />
                  <span class="text-[13px] font-semibold tracking-[-0.02em] text-white">Cuprim</span>
                </div>
                <span class="text-[11px] text-white/40">Refresh</span>
              </div>

              <div class="mac-tabs mx-3 mb-2 flex gap-1 rounded-[9px] p-0.5">
                <span
                  v-for="t in tabs"
                  :key="t"
                  class="flex-1 rounded-[7px] py-1 text-center text-[10.5px] font-medium"
                  :class="t === 'Overview' ? 'bg-white/16 text-white' : 'text-white/45'"
                >{{ t }}</span>
              </div>

              <div class="space-y-2 px-3 pb-3">
                <div
                  v-for="m in meters"
                  :key="m.name"
                  class="mac-meter rounded-[11px] px-3 py-2.5"
                >
                  <div class="mb-1.5 flex items-baseline justify-between gap-2">
                    <span class="text-[11px] font-medium text-white/55">{{ m.name }}</span>
                    <span class="text-[13px] font-semibold tabular-nums tracking-tight text-white/95">
                      {{ m.pct }}%
                    </span>
                  </div>
                  <div class="h-[6px] overflow-hidden rounded-full bg-white/10">
                    <div
                      class="mac-meter__fill h-full rounded-full"
                      :style="{ width: `${m.pct}%` }"
                    />
                  </div>
                  <div class="mt-1 text-right text-[10px] text-white/40">
                    Resets in {{ m.reset }}
                  </div>
                </div>
              </div>
            </div>
          </Transition>

          <!-- Quiet dock hint -->
          <div class="mac-dock" aria-hidden="true">
            <span v-for="n in 5" :key="n" class="mac-dock__icon" />
          </div>

          <!-- Surface control -->
          <div
            class="mac-toggle"
            role="tablist"
            aria-label="Product surface"
          >
            <button
              type="button"
              role="tab"
              class="mac-toggle__btn"
              :class="surface === 'menu' ? 'mac-toggle__btn--active' : ''"
              :aria-selected="surface === 'menu'"
              @click="surface = 'menu'"
            >
              Menu bar
            </button>
            <button
              type="button"
              role="tab"
              class="mac-toggle__btn"
              :class="surface === 'panel' ? 'mac-toggle__btn--active' : ''"
              :aria-selected="surface === 'panel'"
              @click="surface = 'panel'"
            >
              Dashboard
            </button>
          </div>
        </div>
      </div>
    </div>
    <p
      v-if="!embedded"
      class="mt-6 text-center text-[0.84rem] font-medium text-[var(--muted)]"
    >
      Glance in the menu. Detail in the panel.
    </p>
  </section>
</template>

<script setup lang="ts">
import { MENU_PROVIDERS } from "~/utils/site"

withDefaults(
  defineProps<{
    /** Nested inside hero — drop outer wrap padding / caption */
    embedded?: boolean
  }>(),
  { embedded: false },
)

const surface = ref<"menu" | "panel">("menu")
const clock = ref("")
const tabs = ["Overview", "Claude", "Codex"] as const
const meters = [
  { name: "Current window", pct: 42, reset: "2h 18m" },
  { name: "Weekly", pct: 68, reset: "4d" },
] as const

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
})

onUnmounted(() => {
  if (clockTimer) clearInterval(clockTimer)
})
</script>

<style scoped>
.mac-mock--embedded {
  margin-top: 28px;
  padding: 0;
}

@media (min-width: 640px) {
  .mac-mock--embedded {
    margin-top: 36px;
  }
}

.mac-bezel {
  border-radius: 20px;
  border: 1px solid var(--line);
  background: #0e0e10;
  padding: 7px;
  box-shadow:
    0 1px 0 color-mix(in srgb, #fff 8%, transparent) inset,
    0 36px 80px -48px rgba(24, 27, 23, 0.55);
}

.mac-screen {
  position: relative;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  border-radius: 14px;
  background: #07080b;
}

@media (max-width: 560px) {
  .mac-screen {
    aspect-ratio: 10 / 11;
  }
}

/* --- Wallpaper --- */
.mac-wallpaper {
  position: absolute;
  inset: 0;
  z-index: 0;
  background:
    radial-gradient(120% 90% at 50% 110%, #0a1220 0%, transparent 55%),
    linear-gradient(160deg, #121826 0%, #0a0c12 48%, #060708 100%);
}

.mac-wallpaper__glow {
  position: absolute;
  border-radius: 999px;
  filter: blur(40px);
  pointer-events: none;
}

.mac-wallpaper__glow--a {
  top: -10%;
  left: 8%;
  width: 55%;
  height: 55%;
  background: radial-gradient(circle, rgba(40, 90, 170, 0.45), transparent 70%);
}

.mac-wallpaper__glow--b {
  top: 20%;
  right: -8%;
  width: 50%;
  height: 60%;
  background: radial-gradient(circle, rgba(70, 50, 140, 0.28), transparent 70%);
}

.mac-wallpaper__glow--c {
  bottom: -15%;
  left: 30%;
  width: 45%;
  height: 45%;
  background: radial-gradient(circle, rgba(0, 115, 235, 0.18), transparent 70%);
}

.mac-wallpaper__window {
  position: absolute;
  left: 9%;
  top: 18%;
  width: min(42%, 280px);
  height: 58%;
  border-radius: 12px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.07), rgba(255, 255, 255, 0.02)),
    rgba(18, 22, 32, 0.45);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 24px 50px -28px rgba(0, 0, 0, 0.7);
  filter: blur(1.2px);
  opacity: 0.55;
}

.mac-wallpaper__vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(80% 70% at 50% 40%, transparent 35%, rgba(0, 0, 0, 0.45) 100%);
}

.mac-wallpaper__noise {
  position: absolute;
  inset: 0;
  opacity: 0.045;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 140px 140px;
  mix-blend-mode: overlay;
  pointer-events: none;
}

/* --- Menu bar --- */
.mac-menubar {
  position: absolute;
  inset-inline: 0;
  top: 0;
  z-index: 5;
  display: flex;
  height: 30px;
  align-items: center;
  justify-content: space-between;
  padding: 0 14px;
  font-size: 12px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.92);
  background: rgba(8, 10, 14, 0.42);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(22px) saturate(1.4);
  -webkit-backdrop-filter: blur(22px) saturate(1.4);
}

.mac-gauge {
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 5px;
  padding: 2px 4px;
  color: #fff;
  transition:
    background 0.2s ease,
    box-shadow 0.2s ease;
}

.mac-gauge--active {
  background: rgba(255, 255, 255, 0.18);
  box-shadow:
    0 0 0 1px rgba(255, 255, 255, 0.08),
    0 0 18px rgba(255, 255, 255, 0.12);
}

/* --- Shared glass --- */
.mac-glass {
  position: absolute;
  z-index: 6;
  overflow: hidden;
  isolation: isolate;
  border: 1px solid rgba(255, 255, 255, 0.18);
  background:
    linear-gradient(
      165deg,
      rgba(255, 255, 255, 0.14) 0%,
      rgba(255, 255, 255, 0.04) 42%,
      rgba(255, 255, 255, 0.02) 100%
    ),
    rgba(28, 30, 36, 0.58);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.22) inset,
    0 -0.5px 0 rgba(0, 0, 0, 0.35) inset,
    0 18px 50px -14px rgba(0, 0, 0, 0.72),
    0 0 0 0.5px rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(28px) saturate(1.55);
  -webkit-backdrop-filter: blur(28px) saturate(1.55);
}

.mac-glass::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  background: linear-gradient(
    120deg,
    rgba(255, 255, 255, 0.16) 0%,
    transparent 38%,
    rgba(0, 115, 235, 0.06) 100%
  );
  opacity: 0.9;
  z-index: 0;
}

.mac-glass > * {
  position: relative;
  z-index: 1;
}

.mac-menu {
  top: 36px;
  right: 12px;
  width: min(236px, calc(100% - 22px));
  border-radius: 12px;
}

@media (min-width: 640px) {
  .mac-menu {
    right: 48px;
  }
}

.mac-panel {
  top: 40px;
  left: 50%;
  width: min(300px, calc(100% - 28px));
  border-radius: 14px;
  transform: translateX(-50%);
}

.mac-divider {
  height: 1px;
  margin: 2px 10px;
  background: rgba(255, 255, 255, 0.1);
}

.mac-tabs {
  background: rgba(255, 255, 255, 0.07);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.mac-meter {
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.07);
  box-shadow: 0 1px 0 rgba(255, 255, 255, 0.08) inset;
}

.mac-meter__fill {
  background: linear-gradient(90deg, rgba(255, 255, 255, 0.42), rgba(255, 255, 255, 0.72));
}

/* --- Dock hint --- */
.mac-dock {
  position: absolute;
  bottom: 42px;
  left: 50%;
  z-index: 4;
  display: flex;
  transform: translateX(-50%);
  gap: 6px;
  padding: 6px 8px;
  border-radius: 14px;
  background: rgba(20, 22, 28, 0.35);
  border: 1px solid rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  opacity: 0.55;
  pointer-events: none;
}

.mac-dock__icon {
  width: 18px;
  height: 18px;
  border-radius: 5px;
  background: linear-gradient(160deg, rgba(255, 255, 255, 0.28), rgba(255, 255, 255, 0.08));
  box-shadow: 0 1px 0 rgba(255, 255, 255, 0.2) inset;
}

.mac-dock__icon:nth-child(2) {
  background: linear-gradient(160deg, rgba(0, 115, 235, 0.55), rgba(0, 115, 235, 0.2));
}

.mac-dock__icon:nth-child(4) {
  background: linear-gradient(160deg, rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0.05));
}

/* --- Toggle --- */
.mac-toggle {
  position: absolute;
  bottom: 12px;
  left: 50%;
  z-index: 7;
  display: flex;
  transform: translateX(-50%);
  align-items: center;
  gap: 2px;
  padding: 3px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(8, 10, 14, 0.48);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.1) inset,
    0 10px 28px -16px rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(18px) saturate(1.3);
  -webkit-backdrop-filter: blur(18px) saturate(1.3);
}

.mac-toggle__btn {
  border: 0;
  border-radius: 999px;
  padding: 5px 12px;
  font-size: 11px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.5);
  background: transparent;
  cursor: pointer;
  transition:
    color 0.15s ease,
    background 0.15s ease,
    box-shadow 0.15s ease;
}

.mac-toggle__btn:hover {
  color: rgba(255, 255, 255, 0.8);
}

.mac-toggle__btn--active {
  color: #fff;
  background: rgba(255, 255, 255, 0.16);
  box-shadow: 0 1px 0 rgba(255, 255, 255, 0.12) inset;
}

/* --- Surface transition --- */
.mac-surface-enter-active,
.mac-surface-leave-active {
  transition:
    opacity 0.28s cubic-bezier(0.22, 0.9, 0.28, 1),
    transform 0.28s cubic-bezier(0.22, 0.9, 0.28, 1);
}

.mac-surface-enter-from,
.mac-surface-leave-to {
  opacity: 0;
}

.mac-menu.mac-surface-enter-from,
.mac-menu.mac-surface-leave-to {
  transform: translateY(-6px) scale(0.98);
}

.mac-panel.mac-surface-enter-from,
.mac-panel.mac-surface-leave-to {
  transform: translate(-50%, 8px) scale(0.97);
}

@media (prefers-reduced-motion: reduce) {
  .mac-surface-enter-active,
  .mac-surface-leave-active,
  .mac-toggle__btn,
  .mac-gauge {
    transition: none;
  }
}
</style>
