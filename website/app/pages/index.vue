<template>
  <div>
    <SiteNav />
    <main id="top">
      <SiteHero />
      <FeatureScroll />
      <TrustSection />
      <FaqSection />
      <SiteFooter />
    </main>
  </div>
</template>

<script setup lang="ts">
onMounted(() => {
  const nodes = document.querySelectorAll(".reveal")
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  if (reduce) {
    nodes.forEach((el) => el.classList.add("in"))
    return
  }

  // Hero content is above the fold — show immediately so mocks/CTAs never stay blank.
  document.querySelectorAll(".hero .reveal").forEach((el) => el.classList.add("in"))

  const io = new IntersectionObserver(
    (entries) => {
      for (const en of entries) {
        if (en.isIntersecting) {
          en.target.classList.add("in")
          io.unobserve(en.target)
        }
      }
    },
    { threshold: 0.08, rootMargin: "0px 0px -4% 0px" },
  )

  nodes.forEach((el) => {
    if (!el.classList.contains("in")) io.observe(el)
  })
})
</script>
