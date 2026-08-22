# Cuprim delight pass (app + website)

Cuprim should feel like a quiet first-party Mac utility: precise, fast, private.

**Contract:** click the gauge to open the ~300×420 glass dashboard. Settings and Quit stay in the footer. No Share Screenshot. No paywall, accounts, or telemetry.

Usage history is local, bounded (7 days of 5-minute buckets, ~120 KB) and shows
up as at most two things per card: a thin sparkline under each meter and a single
projection line. A projection renders only when it is confident — never an
"insufficient data" placeholder. This replaces the removed Quota Horizon, which
fit a slope from two endpoints and reported reassurance for falling usage.

## Principles

1. Glance in the menu bar, detail in the dashboard.
2. One glass shell, grouped data rows.
3. Every state says what happened, whether last-good data is shown, and what to do next.
4. Recapture website assets from `CUPRIM_DEMO=1` after the app UI is accepted.
