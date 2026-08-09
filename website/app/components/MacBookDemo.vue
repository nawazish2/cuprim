<template>
  <section class="demo" aria-label="Cuprim on a MacBook Air">
    <picture class="demo-poster">
      <source srcset="/macbook-demo-poster.webp" type="image/webp">
      <img
        src="/macbook-demo-poster.webp"
        width="1700"
        height="1120"
        alt="Cuprim’s status menu shown on a MacBook Air desktop"
        fetchpriority="high"
      >
    </picture>

    <div ref="track" class="demo-track" :style="motionStyle" aria-hidden="true">
      <div class="demo-sticky">
        <div class="macbook">
          <div class="macbook-screen">
            <picture>
              <source srcset="/macos-wallpaper.avif" type="image/avif">
              <img src="/macos-wallpaper.webp" width="1586" height="992" alt="">
            </picture>
            <div class="desktop-menu-bar">
              <span class="desktop-menu-bar__left">●&nbsp;&nbsp; Finder&nbsp;&nbsp;&nbsp; File&nbsp;&nbsp;&nbsp; Edit</span>
              <span>Sun Aug 9&nbsp;&nbsp; 1:28 PM</span>
            </div>

            <img
              class="cuprim-surface cuprim-surface--menu"
              src="/cuprim-menu.webp"
              width="298"
              height="852"
              alt=""
              decoding="async"
            >
            <img
              class="cuprim-surface cuprim-surface--dashboard"
              src="/cuprim-dashboard.webp"
              width="720"
              height="930"
              alt=""
              loading="lazy"
              decoding="async"
            >

            <div class="quiet-dock"><span /><span class="quiet-dock__cuprim" /></div>
          </div>
          <img
            class="macbook-frame"
            src="/macbook-frame.webp"
            srcset="/macbook-frame.webp 1x, /macbook-frame@2x.webp 2x"
            width="3400"
            height="2240"
            alt=""
            fetchpriority="high"
          >
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const track = ref<HTMLElement>()
const progress = ref(0)

const clamp = (value: number) => Math.max(0, Math.min(1, value))
const range = (value: number, start: number, end: number) => clamp((value - start) / (end - start))

const motionStyle = computed(() => {
  const p = progress.value
  const menuIn = range(p, 0.2, 0.45)
  const menuOut = range(p, 0.45, 0.65)
  const dashboardIn = range(p, 0.45, 0.65)
  const settle = range(p, 0.65, 0.85)
  const exit = range(p, 0.85, 1)
  const menuOpacity = menuIn * (1 - menuOut)

  return {
    "--device-scale": `${0.88 + 0.12 * range(p, 0, 0.25) - 0.04 * exit}`,
    "--menu-opacity": `${menuOpacity}`,
    "--menu-y": `${18 * (1 - menuIn) - 10 * menuOut}px`,
    "--dashboard-opacity": `${dashboardIn}`,
    "--dashboard-y": `${18 * (1 - dashboardIn) - 4 * settle}px`,
  }
})

let frame = 0
function updateProgress() {
  frame = 0
  if (!track.value) return
  const rect = track.value.getBoundingClientRect()
  progress.value = clamp(-rect.top / Math.max(1, rect.height - window.innerHeight))
}

function onScroll() {
  if (!frame) frame = requestAnimationFrame(updateProgress)
}

onMounted(() => {
  if (window.matchMedia("(max-width: 767px), (prefers-reduced-motion: reduce)").matches) return
  updateProgress()
  window.addEventListener("scroll", onScroll, { passive: true })
  window.addEventListener("resize", onScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener("scroll", onScroll)
  window.removeEventListener("resize", onScroll)
  if (frame) cancelAnimationFrame(frame)
})
</script>

<style scoped>
.demo { margin-top: 30px; }
.demo-poster { display: block; margin: 0 auto; max-width: 100%; }
.demo-poster img { display: block; width: 100%; height: auto; }
.demo-track { display: none; }

@media (min-width: 768px) {
  .demo { margin-top: 38px; }
  .demo-poster { display: none; }
  .demo-track { display: block; height: 220vh; }
  .demo-sticky { position: sticky; top: 0; display: grid; height: 100svh; place-items: center; }
  .macbook { position: relative; width: min(100%, 1080px); transform: scale(var(--device-scale)); transform-origin: center; will-change: transform; }
  .macbook-frame { position: relative; z-index: 3; display: block; width: 100%; height: auto; pointer-events: none; }
  /* The supplied Apple frame has a transparent screen opening that begins above the notch. */
  .macbook-screen { position: absolute; z-index: 1; top: 12.9%; left: 12.35%; width: 75.3%; height: 74.2%; overflow: hidden; background: #060b16; }
  .macbook-screen > picture, .macbook-screen > picture img { display: block; width: 100%; height: 100%; }
  .macbook-screen > picture img { object-fit: cover; }
  .desktop-menu-bar { position: absolute; inset: 0 0 auto; z-index: 1; display: flex; height: 5.3%; align-items: center; justify-content: space-between; padding: 0 2.1%; color: rgb(255 255 255 / 88%); background: rgb(5 9 17 / 44%); font-size: clamp(6px, 0.78vw, 11px); font-weight: 600; backdrop-filter: blur(12px); }
  .desktop-menu-bar__left { letter-spacing: -0.02em; }
  .cuprim-surface { position: absolute; z-index: 2; display: block; height: auto; filter: drop-shadow(0 20px 24px rgb(0 0 0 / 36%)); will-change: transform, opacity; }
  .cuprim-surface--menu { top: 8%; right: 3.7%; width: 16.2%; opacity: var(--menu-opacity); transform: translate3d(0, var(--menu-y), 0); }
  .cuprim-surface--dashboard { top: 13%; right: 11%; width: 31%; opacity: var(--dashboard-opacity); transform: translate3d(0, var(--dashboard-y), 0); }
  .quiet-dock { position: absolute; bottom: 6%; left: 50%; z-index: 1; display: flex; gap: 5px; padding: 5px; transform: translateX(-50%); border: 1px solid rgb(255 255 255 / 14%); border-radius: 12px; background: rgb(10 15 25 / 38%); backdrop-filter: blur(9px); }
  .quiet-dock span { display: block; width: clamp(12px, 1.5vw, 20px); aspect-ratio: 1; border-radius: 5px; background: linear-gradient(140deg, #75aaf5, #285fbb); }
  .quiet-dock__cuprim { background: linear-gradient(140deg, #313846, #121722) !important; }
}

@media (prefers-reduced-motion: reduce) { .demo-track { display: none; } .demo-poster { display: block; } }
</style>
