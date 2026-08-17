# Cuprim website

Nuxt 4 + Tailwind static landing page for [Cuprim](https://github.com/nawazish2/cuprim).

```bash
pnpm install
pnpm run dev      # local
pnpm run generate # static output → .output/public
pnpm run smoke    # after generate
```

Deploy: Cloudflare Workers static assets. `wrangler.jsonc` lives at the repo root.

Dashboard: Worker name `cuprim`, build command `npm run build`, deploy command `npx wrangler deploy`.
Output: `website/.output/public`.
