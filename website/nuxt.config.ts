// https://nuxt.com/docs/api/configuration/nuxt-config
import { SITE } from "./app/utils/site"

const siteUrl = SITE.url.replace(/\/$/, "")
const ogImage = siteUrl ? `${siteUrl}/og.png` : "/og.png"

export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  modules: ["@nuxtjs/tailwindcss"],
  css: ["~/assets/css/main.css"],
  app: {
    head: {
      htmlAttrs: { lang: "en" },
      title: "Cuprim — Know which AI tool runs out next",
      meta: [
        {
          name: "description",
          content:
            "Free open-source macOS menu-bar app for Claude, Codex, Cursor, and Grok quota — local only, no telemetry.",
        },
        { property: "og:title", content: "Cuprim — Know which AI tool runs out next" },
        {
          property: "og:description",
          content: "Menu-bar AI quota for Claude, Codex, Cursor, and Grok. Local only.",
        },
        { property: "og:image", content: ogImage },
        { property: "og:type", content: "website" },
        ...(siteUrl ? [{ property: "og:url", content: `${siteUrl}/` }] : []),
        { name: "twitter:card", content: "summary_large_image" },
        { name: "twitter:title", content: "Cuprim" },
        {
          name: "twitter:description",
          content: "Menu-bar AI quota for Claude, Codex, Cursor, and Grok. Local only.",
        },
        { name: "twitter:image", content: ogImage },
        { name: "theme-color", content: "#f4f6f3" },
      ],
      link: [
        ...(siteUrl ? [{ rel: "canonical" as const, href: `${siteUrl}/` }] : []),
        { rel: "icon" as const, type: "image/png", href: "/favicon.png" },
        { rel: "apple-touch-icon" as const, href: "/icon-192.png" },
      ],
    },
  },
  nitro: {
    preset: "static",
  },
})
