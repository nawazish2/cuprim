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
      height="1281"
      alt="Cuprim dashboard on a Mac desktop, opened from the menu bar"
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
            class="cuprim-surface cuprim-surface--menu"
            src="/cuprim-menu.webp"
            width="298"
            height="852"
            alt=""
            decoding="async"
            loading="lazy"
          >
          <img
            class="cuprim-surface cuprim-surface--dashboard"
            src="/cuprim-dashboard.webp"
            width="720"
            height="930"
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

  .macbook-screen {
    position: absolute;
    z-index: 1;
    top: 12.9%;
    left: 12.35%;
    width: 75.3%;
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

  .cuprim-surface {
    position: absolute;
    z-index: 2;
    display: block;
    height: auto;
    filter: drop-shadow(0 18px 22px rgb(0 0 0 / 32%));
  }

  .cuprim-surface--menu {
    top: 8%;
    right: 3.7%;
    width: 16.2%;
    opacity: 1;
    transform: translate3d(0, 0, 0);
    transition: opacity 0.7s ease, transform 0.7s ease;
  }

  .cuprim-surface--dashboard {
    top: 13%;
    right: 11%;
    width: 31%;
    opacity: 0;
    transform: translate3d(0, 14px, 0);
    transition: opacity 0.7s ease, transform 0.7s ease;
  }

  .is-open .cuprim-surface--menu {
    opacity: 0;
    transform: translate3d(0, -8px, 0);
  }

  .is-open .cuprim-surface--dashboard {
    opacity: 1;
    transform: translate3d(0, 0, 0);
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
