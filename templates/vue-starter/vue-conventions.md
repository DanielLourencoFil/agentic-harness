## Vue conventions (append to AGENTS.md — only what the linter cannot catch)

- **`src/lib/` is the pure core**: domain logic in plain TS, deterministic,
  framework-free, tested hard without mocks. Vue components only render. (An ESLint
  rule bans framework imports in `src/lib/**` — the *shape* of the split is
  convention: compute in lib, wire in stores/composables, render in components.)
- **Derived state = `computed`. `watch`/`watchEffect` ONLY for side-effects/external
  sync; every `watch` carries a one-line justification why computed doesn't fit.**
  (The training corpus over-uses watchers — the linter cannot catch this one.)
- `<script setup>` + Composition API only. Pinia for shared state; props down /
  emits up; no prop drilling past ~2 levels (provide/inject or store).
- Reuse-scan before creating any component or util.
