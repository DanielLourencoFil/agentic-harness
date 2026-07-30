// Copy-paste budget: turns "reuse-scan before creating any util" (AGENTS.md)
// from a rule nobody can check into a number the build refuses to let grow. It
// counts the RESULT, not the intention: a block of significant lines appearing
// twice is a clone, the count is a budget, the budget may only fall. The
// counting lives in ./clone-detect.mjs; this file is the policy.
//
// A budget and not a ban, because a clone detector always argues for extraction
// and the wrong abstraction costs more than the duplication it replaced.
// AGENTS.md says to generalize at the third use case — so this does not demand
// extraction at the second copy, it demands the copy be *declared*, by raising
// the budget in the same commit where a reviewer sees the reason.
//
// A fresh scaffold ships at 0: the zero-warnings rule with a named escape hatch,
// not the warning budget the PLAYBOOK forbids in greenfield — nothing is
// grandfathered because there is nothing yet.
//
// Catches verbatim pastes modulo whitespace, comments and imports. Misses the
// same logic with renamed variables. A token-based detector would find those and
// would need a dependency with a binary download — a bad trade inside `verify`.
//
// Asymmetric on purpose: over budget fails, under budget prints the new number
// and passes. Failing a commit because a refactor REMOVED clones would teach
// people to hate the gate.
//
// Usage:
//   node scripts/clone-budget-check.mjs            check against .clonebudget.json
//   node scripts/clone-budget-check.mjs --report   list the clone groups
//   node scripts/clone-budget-check.mjs --update   write the current count as budget
import { execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

import { findClones, intFromEnv, WINDOW_LINES } from "./clone-detect.mjs";

const ROOT = path.join(import.meta.dirname, "..");
const BUDGET_FILE = path.join(ROOT, ".clonebudget.json");

/**
 * Scanned, relative to the project root. A dir that does not exist is skipped,
 * so this list is a superset: the empty scaffold must keep `verify` green (same
 * class as the TS18003 note in tsconfig.json — a tool that errors on "nothing to
 * do" blocks the kickoff), and a monorepo gets its real roots watched instead of
 * a gate quietly guarding one directory (audit 2026-07-30 flagged the `src`-only
 * scope). Add a root here if the project invents one.
 */
const SCAN_DIRS = ["src", "app", "lib", "apps", "packages"];

function gitLines(command) {
  try {
    // stderr ignored, not inherited: outside a git work tree these commands
    // print ~100 lines of usage text that would bury the gate's own message
    // under noise the author cannot act on.
    return execSync(command, {
      cwd: ROOT,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).split("\n");
  } catch {
    // Each command is tried on its own: `diff HEAD` fails in a repo with no
    // commits yet — which is commit #1, the scaffold — and voiding the other
    // two there would silently drop the scoping exactly when it is needed.
    return [];
  }
}

/**
 * Files this working tree has touched, so a failure points at the author's own
 * code instead of the largest clones in the repo, which they did not write and
 * cannot act on. Best effort: no git, no filter.
 *
 * `--relative` is what makes these paths comparable to `group[i].file`. Without
 * it git prints from the REPO top while clone paths are relative to ROOT, so in
 * any project that is not itself the repo root (`apps/web` in a monorepo) the
 * scoping matched nothing and every failure fell back to "could not tell which
 * are new" — audit 2026-07-30. `ls-files --others` is already cwd-relative.
 */
function touchedFiles() {
  const lines = [
    ...gitLines("git diff --relative --name-only HEAD"),
    ...gitLines("git diff --relative --cached --name-only"),
    ...gitLines("git ls-files --others --exclude-standard"),
  ];
  return new Set(lines.map((line) => line.trim()).filter(Boolean));
}

function printGroups(groups, log) {
  for (const group of groups) {
    log(`   ${group.length}× ${group[0].file}:${group[0].startLine}`);
    for (const o of group.slice(1)) log(`       ↳ ${o.file}:${o.startLine}`);
  }
}

function report({ groups, total, fileCount }) {
  const limit = intFromEnv("CLONE_REPORT_LIMIT", 25, 0);
  console.log(
    `🔍 ${groups.length} clone groups, ${total} copies beyond the original, in ${fileCount} files\n`,
  );
  printGroups(limit === 0 ? groups : groups.slice(0, limit), console.log);
  if (limit !== 0 && groups.length > limit) {
    console.log(`   … and ${groups.length - limit} more (CLONE_REPORT_LIMIT=0)`);
  }
}

function writeBudget(total) {
  const budget = {
    maxDuplicateBlocks: total,
    windowLines: WINDOW_LINES,
    updatedAt: new Date().toISOString().slice(0, 10),
    note: "Copies beyond the original, counted by scripts/clone-budget-check.mjs. This number may go down, never up.",
  };
  writeFileSync(BUDGET_FILE, `${JSON.stringify(budget, null, 2)}\n`);
  console.log(`✅ Budget written: ${total}`);
}

/** The budget, or a loud exit. A missing `maxDuplicateBlocks` used to surface as
 *  `1 > undefined` — it failed closed, which is right, but said nothing useful.
 *  And `windowLines` was written by --update and never read again, so a budget
 *  measured at one window was silently enforced at another, comparing numbers
 *  this file's own header calls incomparable (audit 2026-07-30). */
function readBudget() {
  if (!existsSync(BUDGET_FILE)) {
    console.error(
      "❌ .clonebudget.json not found. Create it: node scripts/clone-budget-check.mjs --update",
    );
    process.exit(1);
  }
  const budget = JSON.parse(readFileSync(BUDGET_FILE, "utf8"));
  if (
    !Number.isInteger(budget.maxDuplicateBlocks) ||
    budget.maxDuplicateBlocks < 0
  ) {
    console.error(
      `❌ .clonebudget.json needs an integer maxDuplicateBlocks >= 0, found ${JSON.stringify(budget.maxDuplicateBlocks)}`,
    );
    process.exit(1);
  }
  if (
    Number.isInteger(budget.windowLines) &&
    budget.windowLines !== WINDOW_LINES
  ) {
    console.error(
      `❌ Budget measured at windowLines=${String(budget.windowLines)}, running at ${String(WINDOW_LINES)}.\n` +
        "   Counts are not comparable across windows. Unset CLONE_WINDOW_LINES, or regenerate with --update.",
    );
    process.exit(1);
  }
  return budget;
}

function enforce({ groups, total }) {
  const max = readBudget().maxDuplicateBlocks;
  if (total <= max) {
    const hint = total < max ? " — ratchet it down: --update" : `/${max}`;
    console.log(`✅ Copy-paste budget: ${total}${hint}`);
    return;
  }
  const touched = touchedFiles();
  const mine = groups.filter((g) => g.some((o) => touched.has(o.file)));
  console.error(`\n❌ Copy-paste budget exceeded: ${total} > ${max}`);
  console.error(
    mine.length > 0
      ? "   Clones involving files you touched:\n"
      : "   Could not tell which are new; largest clone groups:\n",
  );
  printGroups((mine.length > 0 ? mine : groups).slice(0, 5), console.error);
  console.error("\n   Full list: node scripts/clone-budget-check.mjs --report");
  console.error(
    "   If the duplication is deliberate, say so and raise the budget in the same commit.",
  );
  process.exit(1);
}

const found = findClones(
  SCAN_DIRS.map((d) => path.join(ROOT, d)).filter((d) => existsSync(d)),
  ROOT,
);

const mode = process.argv[2];
if (mode === "--report") report(found);
else if (mode === "--update") writeBudget(found.total);
else enforce(found);
