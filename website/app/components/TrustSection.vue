<template>
  <section id="privacy" class="section">
    <div class="wrap">
      <div class="section-eyebrow">Privacy</div>
      <h2 class="section-title">Credentials stay on your Mac.</h2>
      <p class="section-lead mt-3">
        Cuprim talks only to each provider’s own usage API. There is no Cuprim account, no telemetry, and no backend of ours.
      </p>
      <ol class="flow mt-10" aria-label="Where credentials go">
        <li>
          <strong>On this Mac</strong>
          <span>Claude, Codex, Cursor, and Grok keep their own sign-in.</span>
        </li>
        <li>
          <strong>Cuprim</strong>
          <span>Reads those local sessions and asks only for quota.</span>
        </li>
        <li>
          <strong>Provider APIs</strong>
          <span>Usage data comes back to the menu bar. Nothing is sent to us.</span>
        </li>
      </ol>
    </div>
  </section>
</template>

<style scoped>
.flow {
  display: grid;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
  max-width: 640px;
}

.flow li {
  display: grid;
  gap: 4px;
  padding: 16px 18px;
  border-radius: 14px;
  background: color-mix(in srgb, var(--surface) 72%, transparent);
  border: 1px solid var(--line-soft);
}

.flow strong {
  font-size: 1rem;
  letter-spacing: -0.02em;
}

.flow span {
  color: var(--muted);
  line-height: 1.4;
}
</style>
