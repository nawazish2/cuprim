export const SITE = {
  name: "Cuprim",
  version: "v0.1.4",
  tagline: "AI quota in your Mac menu bar",
  description:
    "Free local macOS app that shows Claude, Codex, Cursor, and Grok usage. No accounts with us. No telemetry.",
  url: "https://cuprim.vercel.app",
  github: "https://github.com/nawazish2/cuprim",
  releasesLatest: "https://github.com/nawazish2/cuprim/releases/latest",
  releases: "https://github.com/nawazish2/cuprim/releases",
  issues: "https://github.com/nawazish2/cuprim/issues",
  license: "https://github.com/nawazish2/cuprim/blob/main/LICENSE",
} as const

/** Status-menu style rows (matches the real NSMenu glance — monochrome, no color chips). */
export const MENU_PROVIDERS = [
  { name: "Claude", plan: "Free", status: "86% · 2h" },
  { name: "Codex", plan: "Go", status: "Limit Reached" },
  { name: "Cursor", plan: "Pro", status: "31% · 12d" },
  { name: "Grok", plan: "SuperGrok", status: "Unavailable" },
] as const
