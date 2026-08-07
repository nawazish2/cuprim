<template>
  <div>
    <div
      class="pointer-events-none fixed inset-0 z-0"
      aria-hidden="true"
      style="
        background:
          radial-gradient(900px 480px at 50% -10%, rgba(224, 138, 76, 0.14), transparent 65%),
          radial-gradient(700px 420px at 88% 30%, rgba(185, 98, 47, 0.07), transparent 60%),
          radial-gradient(700px 420px at 8% 62%, rgba(224, 138, 76, 0.05), transparent 60%);
      "
    />
    <div class="grain pointer-events-none fixed inset-0 z-[2]" aria-hidden="true" />

    <div class="relative z-[1]">
      <SiteNav />
      <main id="top">
        <SiteHero />
        <MacMock />
        <FeatureScroll />
        <TrustSection />
        <FaqSection />
        <SiteFooter />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
onMounted(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  if (reduce) {
    document.querySelectorAll(".reveal").forEach((el) => el.classList.add("in"))
    return
  }

  const io = new IntersectionObserver(
    (entries) => {
      for (const en of entries) {
        if (en.isIntersecting) {
          en.target.classList.add("in")
          io.unobserve(en.target)
        }
      }
    },
    { threshold: 0.18 },
  )

  document.querySelectorAll(".reveal").forEach((el) => io.observe(el))
})
</script>
