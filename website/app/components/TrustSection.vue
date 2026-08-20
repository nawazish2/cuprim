<template>
  <section id="privacy" class="section section--product">
    <div class="wrap">
      <div class="reveal">
        <div class="section-eyebrow">Privacy</div>
        <h2 class="section-title section-title--left">Credentials stay on your Mac.</h2>
        <p class="section-lead section-lead--left mt-3">
          Cuprim talks only to each provider’s own usage API. There is no Cuprim account, no telemetry, and no backend of ours.
        </p>
      </div>
      <ol class="statement-list reveal d2" aria-label="Where credentials go">
        <li class="statement-row">
          <div class="statement-title">On this Mac</div>
          <div class="statement-body">Claude, Codex, Cursor, and Grok keep their own sign-in.</div>
        </li>
        <li class="statement-row">
          <div class="statement-title">Cuprim</div>
          <div class="statement-body">Reads those local sessions and asks only for quota.</div>
        </li>
        <li class="statement-row">
          <div class="statement-title">Provider APIs</div>
          <div class="statement-body">Usage data comes back to the menu bar. Nothing is sent to us.</div>
        </li>
      </ol>
    </div>
  </section>
</template>
