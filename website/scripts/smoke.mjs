import { readFileSync, existsSync } from "node:fs"
import { resolve } from "node:path"

const root = resolve(import.meta.dirname, "..")
const lintOnly = process.argv.includes("--lint")

if (lintOnly) {
  const files = [
    "app/pages/index.vue",
    "app/components/SiteHero.vue",
    "app/utils/site.ts",
  ]
  for (const file of files) {
    const text = readFileSync(resolve(root, file), "utf8")
    if (text.includes("Every AI quota") || text.includes("MENU_PROVIDERS")) {
      console.error(`lint: stale copy in ${file}`)
      process.exit(1)
    }
  }
  console.log("lint ok")
  process.exit(0)
}

const htmlPath = resolve(root, ".output/public/index.html")
if (!existsSync(htmlPath)) {
  console.error("smoke: generate the site first (pnpm run generate)")
  process.exit(1)
}

const html = readFileSync(htmlPath, "utf8")
const needles = [
  "Know which AI tool",
  "Download Cuprim",
  "Antigravity",
  "Skip to content",
  "Click the gauge",
  "Credentials stay on your Mac",
  "Sparkle",
]
for (const needle of needles) {
  if (!html.includes(needle)) {
    console.error(`smoke: missing “${needle}”`)
    process.exit(1)
  }
}
if (html.includes("Every AI quota") || html.includes("v0.1.6")) {
  console.error("smoke: stale marketing copy still present")
  process.exit(1)
}
console.log("smoke ok")
