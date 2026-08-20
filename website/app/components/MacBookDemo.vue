<template>
  <section
    class="demo"
    :class="{ 'is-layered': stageReady, 'is-open': opened }"
    aria-label="Cuprim on a MacBook"
  >
    <img
      class="demo-poster"
      src="/macbook-demo-poster.webp"
      width="1700"
      height="1260"
      alt="Cuprim dashboard open on a Mac desktop, opened from the menu bar gauge"
      fetchpriority="high"
    >

    <div v-if="stageReady" ref="stage" class="demo-stage" aria-hidden="true">
      <div class="macbook">
        <div class="macbook-screen">
          <img
            class="wallpaper"
            src="/macos-wallpaper.webp"
            width="1586"
            height="992"
            alt=""
            decoding="async"
            loading="lazy"
          >
          <img
            class="gauge"
            src="/cuprim-gauge.webp"
            width="160"
            height="160"
            alt=""
            decoding="async"
            loading="lazy"
          >
          <img
            class="panel"
            src="/cuprim-dashboard.webp"
            width="600"
            height="840"
            alt=""
            decoding="async"
            loading="lazy"
          >
        </div>
        <img
          class="macbook-frame"
          src="/macbook-frame.webp"
          width="1700"
          height="1120"
          alt=""
          loading="lazy"
        >
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const stage = ref<HTMLElement>()
const opened = ref(false)
const stageReady = ref(false)

onMounted(() => {
  const reduce = window.matchMedia("(max-width: 767px), (prefers-reduced-motion: reduce)").matches
  if (reduce) return
  stageReady.value = true
  nextTick(() => {
    if (!stage.value) return
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          opened.value = true
          io.disconnect()
        }
      },
      { threshold: 0.35 },
    )
    io.observe(stage.value)
    onUnmounted(() => io.disconnect())
  })
})
</script>

<style scoped>
.demo {
  margin-top: 8px;
}

.demo-poster {
  display: block;
  margin: 0 auto;
  width: 100%;
  height: auto;
}

.demo-stage {
  display: none;
}

@media (min-width: 768px) {
  .demo.is-layered .demo-poster {
    display: none;
  }

  .demo.is-layered .demo-stage {
    display: block;
  }

  .macbook {
    position: relative;
    width: min(100%, 640px);
    margin-left: auto;
  }

  .macbook-frame {
    position: relative;
    z-index: 3;
    display: block;
    width: 100%;
    height: auto;
    pointer-events: none;
  }

  /* Measured against macbook-frame.webp's transparent screen cutout. */
  .macbook-screen {
    position: absolute;
    z-index: 1;
    top: 12.86%;
    left: 12.35%;
    width: 75.29%;
    height: 74.2%;
    overflow: hidden;
    background: #101318;
  }

  .wallpaper {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  /* Always visible — the status item stays put whether the panel is open or not. */
  .gauge {
    position: absolute;
    z-index: 2;
    top: 4%;
    right: 8%;
    width: 5%;
    height: auto;
  }

  .panel {
    position: absolute;
    z-index: 2;
    top: 10%;
    right: 5%;
    width: 34%;
    height: auto;
    opacity: 0;
    transform: translate3d(0, -10px, 0) scale(0.96);
    transform-origin: top right;
    filter: drop-shadow(0 18px 22px rgb(0 0 0 / 32%));
    transition: opacity 0.7s ease, transform 0.7s ease;
  }

  .is-open .panel {
    opacity: 1;
    transform: translate3d(0, 0, 0) scale(1);
  }
}

@media (prefers-reduced-motion: reduce) {
  .demo-stage {
    display: none !important;
  }

  .demo-poster {
    display: block !important;
  }
}
</style>
