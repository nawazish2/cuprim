export const SITE = {
  name: "Cuprim",
  version: "v0.1.3",
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

export const PROVIDERS = [
  { name: "Claude", plan: "Pro · 5h window", pct: 68, color: "#D97757", reset: "1:12:08" },
  { name: "Codex", plan: "Plus · usage", pct: 31, color: "#10A37F", reset: "4:03:12" },
  { name: "Cursor", plan: "Pro · monthly", pct: 78, color: "#88C0FF", reset: "12d" },
  { name: "Grok", plan: "SuperGrok · weekly", pct: 12, color: "#E8E8E8", reset: "21:47:55" },
] as const
