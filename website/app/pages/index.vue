<template>
  <div>
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
