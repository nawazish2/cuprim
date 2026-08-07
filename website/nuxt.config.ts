// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  modules: ["@nuxtjs/tailwindcss"],
  css: ["~/assets/css/main.css"],
  app: {
    head: {
      htmlAttrs: { lang: "en" },
      title: "Cuprim — AI quotas, live in your Mac menu bar",
      meta: [
        {
          name: "description",
          content:
            "Free open-source macOS menu-bar app for Claude, Codex, Cursor, and Grok quota — local only, no telemetry.",
        },
        { property: "og:title", content: "Cuprim — AI quotas, live in your Mac menu bar" },
        {
          property: "og:description",
          content: "Every AI quota, right at the rim. Free, open source, native Swift.",
        },
        { property: "og:image", content: "https://cuprim.vercel.app/og.png" },
        { property: "og:type", content: "website" },
        { property: "og:url", content: "https://cuprim.vercel.app/" },
        { name: "twitter:card", content: "summary_large_image" },
        { name: "twitter:title", content: "Cuprim" },
        {
          name: "twitter:description",
          content: "Menu-bar AI quota for Claude, Codex, Cursor, and Grok. Local only.",
        },
        { name: "twitter:image", content: "https://cuprim.vercel.app/og.png" },
        { name: "theme-color", content: "#0a0908" },
      ],
      link: [
        { rel: "icon", type: "image/png", href: "/favicon.png" },
        { rel: "apple-touch-icon", href: "/icon-192.png" },
      ],
    },
  },
  nitro: {
    preset: "static",
  },
})
