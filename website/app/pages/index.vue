<template>
  <div id="top">
    <a class="skip-link" href="#main">Skip to content</a>
    <SiteNav />
    <main id="main">
      <SiteHero />
      <GlanceSection />
      <ProvidersSection />
      <TrustSection />
      <InstallSection />
      <FaqSection />
      <SiteFooter />
    </main>
  </div>
</template>

<script setup lang="ts">
import { SITE } from "~/utils/site"

useHead({
  script: [
    {
      type: "application/ld+json",
      innerHTML: JSON.stringify({
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        name: SITE.name,
        applicationCategory: "UtilitiesApplication",
        operatingSystem: "macOS 26",
        offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
        ...(SITE.url ? { url: SITE.url } : {}),
        downloadUrl: SITE.releasesLatest,
        description: SITE.description,
      }),
    },
  ],
})

onMounted(() => {
  // Owns js-enhance for the whole page (the FAQ accordion's no-JS fallback
  // and the .reveal scroll-in system both key off this).
  document.documentElement.classList.add("js-enhance")

  const nodes = document.querySelectorAll(".reveal")
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  if (reduce) {
    nodes.forEach((el) => el.classList.add("in"))
    return
  }
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
    // Trigger while a section is still below the fold (positive bottom
    // margin expands the root downward) so normal scrolling never shows a
    // blank flash waiting for the fade-in to catch up.
    { threshold: 0, rootMargin: "0px 0px 20% 0px" },
  )
  nodes.forEach((el) => {
    if (!el.classList.contains("in")) io.observe(el)
  })
})
</script>

<style>
.skip-link {
  position: absolute;
  left: 12px;
  top: -40px;
  z-index: 80;
  padding: 8px 12px;
  border-radius: 8px;
  background: var(--ink);
  color: #fff;
}
.skip-link:focus {
  top: 12px;
}
</style>
