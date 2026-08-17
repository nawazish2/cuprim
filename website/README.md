# Cuprim website

Nuxt 4 + Tailwind static landing page for [Cuprim](https://github.com/nawazish2/cuprim).

```bash
pnpm install
pnpm run dev      # local
pnpm run generate # static output → .output/public
pnpm run smoke    # after generate
```

Deploy: Cloudflare Workers static assets. `wrangler.jsonc` lives at the repo root; build with `pnpm run generate` (output `.output/public`).
