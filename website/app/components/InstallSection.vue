<template>
  <section id="install" class="section section--product">
    <div class="wrap reveal">
      <div class="section-eyebrow">Install</div>
      <h2 class="section-title section-title--left">Download, then open once.</h2>
      <p class="section-lead section-lead--left mt-3">
        Current builds are ad-hoc signed. Sparkle verifies later updates. Developer ID notarization is optional.
      </p>
      <ol class="steps mt-10">
        <li>Download Cuprim from GitHub Releases and drag it into Applications.</li>
        <li>
          If macOS blocks the first open, Control-click the app and choose
          <strong>Open</strong>, or run
          <code class="code-snippet !mt-2">xattr -cr /Applications/Cuprim.app</code>
        </li>
        <li>Look for the gauge in the menu bar. Click it for the dashboard.</li>
      </ol>
    </div>
  </section>
</template>

<style scoped>
.steps {
  max-width: 58ch;
  margin: 0;
  padding-left: 1.2em;
  color: var(--muted);
  line-height: 1.5;
}

.steps li + li {
  margin-top: 12px;
}

.steps strong {
  color: var(--ink);
}
</style>
