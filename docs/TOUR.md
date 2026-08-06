# TOUR — see the harness bite, in ten minutes

Every claim below is demonstrated live, not narrated. Prerequisites: node ≥22, pnpm,
git. Total time: ~15 minutes, of which ~3 are `pnpm install`.

## 1. The system proves itself (1 min)

Open the [Actions tab](https://github.com/DanielLourencoFil/agentic-harness/actions).
Every push runs the selftest suite. Some jobs (`selftest`, `selftest-vue`,
`selftest-react`) consume the templates exactly as the READMEs instruct, in a throwaway
directory. `selftest-home` pipe-tests every machine-layer hook against a planted
violation. `selftest-skills` holds the claims ledger to its own contract — a shipped
artefact with no row fails the build, a force-degree claim citing a missing executor
fails, and a verify step that drifted out of the docs fails. All of them fail if a
promise regresses, including the promise that the gate *rejects* bad code. Or run one
yourself:

```bash
git clone https://github.com/DanielLourencoFil/agentic-harness && cd agentic-harness
bash scripts/selftest.sh
```

Expected final line: `SELFTEST OK — … guard blocks, gate rejects.`

## 2. Consume the template; verify is green on an empty project (3 min)

Follow `templates/ts-base/README.md` steps 1–5 (git init → copy → merge snippet →
install → verify). The empty scaffold verifies green **by construction** — that exact
claim once failed on all three steps, which is why the selftest exists
([AGENT-LOG, 2026-07-09](../AGENT-LOG.md)).

## 3. Try to commit bad code (2 min)

In the consumed project:

```bash
cat > src/bad.ts <<'EOF'
export function f(x: any) {
  return x == 1;
}
EOF
git add -A && git commit -m "test"
```

The commit is **rejected** — `no-explicit-any` and `eqeqeq` fire in the pre-commit
verify. Not a warning, not a convention: the commit does not exist.

## 4. Try to delete a feature quietly (1 min)

```bash
seq 1 100 > feature.txt && git add feature.txt && git commit -m "seed"
git rm feature.txt && git commit -m "cleanup"
```

Blocked: `❌ Deletion guard: 100 lines deleted (limit 80)`. Large removals need an
explicit flag — nothing disappears silently.

## 5. Try to paste code instead of reusing it (1 min)

In the consumed project, copy any eight-line block into a second file, then:

```bash
pnpm clones
```

Rejected: `❌ Copy-paste budget exceeded: 1 > 0`, and the failure names the file you
just touched rather than the repo's worst offenders. The count may only fall; a
deliberate duplicate is allowed but has to be declared by raising the budget in the
same commit, where a reviewer sees the reason next to the copy.

## 6. Try to strand pure logic in a component (1 min)

Write a pure function inside a `.tsx` renderer — logic that could only be tested by
mounting the component:

```bash
mkdir -p src/components
printf 'function scoreRow(a, b) {\n  const t = a + b;\n  const ok = t > 0;\n  return ok ? t : 0;\n}\nexport function Row() { return null; }\n' > src/components/row.tsx
pnpm stranded
```

Rejected: `❌ Stranded-logic budget exceeded: 1 > 0`, naming `scoreRow`. Move it to
`src/lib` and the count returns to 0. This is "components render, `lib` decides" made
mechanical: logic in the wrong place, where it is expensive to test, cannot land.

## 7. Prove your tests can actually fail (2 min)

Write a pure function and a test that never pins its boundary, then mutate:

```bash
printf 'export const eligible = (age) => age >= 18;\n' > src/lib/eligible.ts
printf 'import { expect, test } from "vitest";\nimport { eligible } from "./eligible";\ntest("weak", () => { expect(eligible(20)).toBe(true); });\n' > src/lib/eligible.test.ts
pnpm mutants
```

Rejected: a mutant survives — Stryker changed `>=` to `>` and no test noticed, because
the test never checks age 18. Coverage would call this line "covered"; mutation calls
the test decorative. Add `expect(eligible(18)).toBe(true)` and it passes. This is the
wired half of "every test must fail if the logic breaks".

## 8. The machine layer bites with no project at all (1 min)

The gates above live in the project. These travel with the machine, so they hold in a
session opened anywhere — including someone else's repo, where nothing may be
installed. No project needed to see one refuse:

```bash
printf '{"tool_name":"Write","cwd":"/tmp/demo","tool_input":{"file_path":"%s/.ssh/authorized_keys"}}' "$HOME" \
  | CLAUDE_PROJECT_DIR=/tmp/demo python3 home/bin/write-containment.py
```

It denies, naming the real resolved path and the short allowlist of what may be
written outside the project root. `../` and symlink escapes are resolved before the
check, and each of those cases is a negative test in `selftest-home`.

Honest limit, measured rather than assumed: this binds the **file tools**. Bash is not
contained by it, and on this machine nothing else contains it either
([ADR 29](DECISIONS.md)) — the harness says so in its own docs instead of implying a
wall that is not there.

## 9. Try to bypass everything (1 min)

`git commit --no-verify` is denied to the agent by `.claude/settings.json`; and even
a bypassed local hook dies at the server — the repo's ruleset requires a PR with the
green `selftest` check to touch `main`. Local gates are convenience; **the server-side
gate is the guarantee**, and it binds humans, agents and bots alike.

## 10. Why these rules and not others (2 min)

Read [`docs/RATIONALE.md`](RATIONALE.md) — the four-category taxonomy (validity,
examinability, procedure, human judgment) and the honest limits (tools verify form,
never content). The extended, principle-by-principle treatment lives in
[rational-code](https://github.com/DanielLourencoFil/rational-code); the incident
history lives in the [AGENT-LOG](../AGENT-LOG.md), confabulation counts included.
