// Diff-size nudge (C-072): a branch far past ~300 added lines is usually two
// changes wearing one PR, and a reviewer reads two small diffs faster and better
// than one large one.
//
// WARN, never block, and this is a deliberate design choice, not timidity. The
// per-file `max-lines: 300` cap is the wired half and it blocks; total added
// diff is a fuzzy branch-level metric, and a hard block on it would punish work
// that is large but coherent (a template plus its selftest, a doc sweep) and
// teach people to split by line count rather than by concern. So it prints a
// loud line and exits 0. The decision to split stays human; the gate only makes
// the size impossible to not notice.
//
// Measured against the default branch, not per commit: splitting is a PR-level
// concern, and "300 lines" means 300 lines of THIS branch's work, so the
// comparison is the merge-base with origin/main. No git, no default branch, no
// nudge: it fails open, because a size hint is not worth breaking a commit over.
//
// Lockfiles and generated files are excluded: a lockfile bump is not review
// surface, and counting it would fire the nudge on a dependency change that has
// almost no code in it.
import { execSync } from "node:child_process";

const BUDGET = Number(process.env.DIFF_SIZE_BUDGET ?? 300);
const BASE_REF = process.env.DIFF_SIZE_BASE ?? "origin/main";
const SKIP = /(^|\/)(pnpm-lock\.yaml|package-lock\.json|yarn\.lock)$|(^|\/)__generated__\//;

function git(command) {
  return execSync(command, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
}

function addedLines() {
  // The merge-base: only what THIS branch added on top of the base, never the
  // base's own history. `--` guards a ref that shares a name with a path.
  const base = git(`git merge-base ${BASE_REF} HEAD`).trim();
  const numstat = git(`git diff --numstat ${base} HEAD --`);
  let added = 0;
  for (const line of numstat.split("\n")) {
    const [add, , file] = line.split("\t");
    if (!file || SKIP.test(file)) continue;
    const n = Number(add);
    if (!Number.isNaN(n)) added += n;
  }
  return added;
}

let added;
try {
  added = addedLines();
} catch {
  // No git, no base ref, detached state: a nudge is not worth an error. Fail open.
  process.exit(0);
}

if (added > BUDGET) {
  console.warn(
    `\n⚠️  Diff-size nudge: ${added} lines added vs ${BASE_REF} (soft budget ${BUDGET}).\n` +
      `   A branch this size is often two changes in one PR. If it is one coherent\n` +
      `   change, ignore this. If it is not, splitting it makes the review land.\n` +
      `   This is a warning, never a block (C-072). Tune with DIFF_SIZE_BUDGET.\n`,
  );
}
process.exit(0);
