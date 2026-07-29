// Copy-paste budget: turns "reuse-scan before creating any util" (AGENTS.md)
// from a rule nobody can check into a number the build refuses to let grow.
//
// It counts the RESULT instead of asking for the intention. A block of
// significant lines that appears in two places is a clone; the number of clones
// is a budget; the budget may only go down.
//
// Why a budget and not a ban: a clone detector always argues for extraction, and
// the wrong abstraction costs more than the duplication it replaced. AGENTS.md
// says to generalize at the third use case, never before — so this gate does not
// demand extraction at the second copy, it demands that the copy be *declared*.
// Raising the budget in the same commit is the sanctioned move; the number is the
// standing record of how many undeclared pastes exist.
//
// In a fresh scaffold the budget ships at 0, so this is the zero-warnings rule
// with a named escape hatch, not a warning budget (which the PLAYBOOK forbids in
// greenfield): nothing is grandfathered, because there is nothing yet.
//
// What it catches: blocks pasted verbatim, modulo whitespace, comments and import
// lines. What it misses: the same logic with renamed variables, and duplication
// spread across shapes rather than lines. A token-based detector would find those
// and would also need a dependency with a binary download — a bad trade for
// something that runs inside `verify`.
//
// Asymmetry, on purpose: over budget fails, under budget prints the new number
// and passes. A single global count is a fuzzy metric, and failing a commit
// because a refactor REMOVED clones would teach people to hate the gate.
//
// Usage:
//   node scripts/clone-budget-check.mjs            check against .clonebudget.json
//   node scripts/clone-budget-check.mjs --report   list the clone groups
//   node scripts/clone-budget-check.mjs --update   write the current count as budget
import { execSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

const ROOT = path.join(import.meta.dirname, "..");
const BUDGET_FILE = path.join(ROOT, ".clonebudget.json");

/** Scanned, relative to the project root. A dir that does not exist is skipped:
 *  the empty scaffold must keep `verify` green (same class as the TS18003 note in
 *  tsconfig.json — a tool that errors on "nothing to do" blocks the kickoff). */
const SCAN_DIRS = ["src"];

/**
 * A window this long is a clone. Measured, not picked — on the repo that
 * motivated this gate (calendar-app, 2026-07-29):
 *
 *   window │ groups │ copies │ found the 15× matchMedia block?
 *   ───────┼────────┼────────┼─────────────────────────────────
 *      8   │  553   │  753   │ yes, as a 4× group
 *     10   │  317   │  405   │ no
 *     12   │  211   │  259   │ no
 *
 * The block that justified the gate is eight significant lines long, so a longer
 * window is quieter and blind to exactly the case it exists for.
 *
 * Override with CLONE_WINDOW_LINES to explore; changing the default means
 * regenerating the budget, since counts are not comparable across windows.
 */
const WINDOW_LINES = Number(process.env.CLONE_WINDOW_LINES ?? 8);

const SKIP_DIRS = new Set(["node_modules", "dist", "build", "coverage"]);

/** Tests repeat their arrange blocks by nature (AGENTS.md prefers that to clever
 *  shared helpers), and generated files are written by no one. Neither is a
 *  copy-paste anybody should answer for. */
const SKIP_FILE = /\.(spec|test)\.tsx?$|\.d\.ts$/;
const SOURCE_FILE = /\.tsx?$/;

function walk(dir, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) walk(full, out);
    } else if (SOURCE_FILE.test(entry.name) && !SKIP_FILE.test(entry.name)) {
      out.push(full);
    }
  }
  return out;
}

/** Import blocks look alike in every file of every codebase and would drown the
 *  signal in noise nobody can act on. Comments and blanks likewise. */
const isNoise = (line) =>
  !line ||
  line.startsWith("//") ||
  line.startsWith("*") ||
  /^(import|export)\s.*\bfrom\b/.test(line);

/** Lines that carry logic, with their original line numbers. */
function significantLines(source) {
  const kept = [];
  const lines = source.split("\n");
  let inComment = false;
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].trim();
    if (inComment) {
      const end = line.indexOf("*/");
      if (end === -1) continue;
      line = line.slice(end + 2).trim();
      inComment = false;
    }
    if (line.startsWith("/*")) {
      inComment = !line.includes("*/");
      continue;
    }
    if (isNoise(line)) continue;
    // Collapse internal whitespace so reformatting cannot hide a clone.
    kept.push({ text: line.replace(/\s+/g, " "), line: i + 1 });
  }
  return kept;
}

function collectWindows(files) {
  /** hash → [{ file, startLine, endLine }] */
  const byHash = new Map();
  for (const file of files) {
    const lines = significantLines(readFileSync(file, "utf8"));
    for (let i = 0; i + WINDOW_LINES <= lines.length; i++) {
      const slice = lines.slice(i, i + WINDOW_LINES);
      const key = createHash("sha1")
        .update(slice.map((l) => l.text).join("\n"))
        .digest("hex");
      const entry = {
        file: path.relative(ROOT, file),
        startLine: slice[0].line,
        endLine: slice[slice.length - 1].line,
      };
      if (byHash.has(key)) byHash.get(key).push(entry);
      else byHash.set(key, [entry]);
    }
  }
  return byHash;
}

/**
 * Clone groups, with overlapping windows collapsed.
 *
 * A twenty-line duplicated block produces thirteen overlapping eight-line
 * windows. Counting those as thirteen clones would make the number depend on the
 * LENGTH of the block rather than on how many times someone pasted it, so a
 * window whose lines are already claimed by an accepted group is dropped.
 */
function cloneGroups(byHash) {
  const candidates = [...byHash.entries()]
    .filter(([, occurrences]) => occurrences.length > 1)
    .sort((a, b) =>
      b[1].length === a[1].length
        ? a[1][0].file.localeCompare(b[1][0].file)
        : b[1].length - a[1].length,
    );

  /** file → array of [start, end] already claimed */
  const covered = new Map();
  const isCovered = (o) =>
    (covered.get(o.file) ?? []).some(
      ([start, end]) => o.startLine <= end && o.endLine >= start,
    );

  const groups = [];
  for (const [, occurrences] of candidates) {
    const free = occurrences.filter((o) => !isCovered(o));
    if (free.length < 2) continue;
    for (const o of free) {
      if (!covered.has(o.file)) covered.set(o.file, []);
      covered.get(o.file).push([o.startLine, o.endLine]);
    }
    groups.push(free);
  }
  return groups;
}

/** Files this working tree has touched, so a failure points at the author's own
 *  code instead of the largest clones in the repo, which they did not write and
 *  cannot act on. Best effort: no git, no filter. */
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

function touchedFiles() {
  const lines = [
    ...gitLines("git diff --name-only HEAD"),
    ...gitLines("git diff --cached --name-only"),
    ...gitLines("git ls-files --others --exclude-standard"),
  ];
  return new Set(lines.map((l) => l.trim()).filter(Boolean));
}

function printGroups(groups, log) {
  for (const group of groups) {
    log(`   ${group.length}× ${group[0].file}:${group[0].startLine}`);
    for (const o of group.slice(1)) log(`       ↳ ${o.file}:${o.startLine}`);
  }
}

function report(groups, total, fileCount) {
  const limit = Number(process.env.CLONE_REPORT_LIMIT ?? 25);
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

function enforce(groups, total) {
  if (!existsSync(BUDGET_FILE)) {
    console.error(
      "❌ .clonebudget.json not found. Create it: node scripts/clone-budget-check.mjs --update",
    );
    process.exit(1);
  }
  const max = JSON.parse(readFileSync(BUDGET_FILE, "utf8")).maxDuplicateBlocks;
  if (total <= max) {
    const hint =
      total < max ? ` — ratchet it down: --update` : `/${max}`;
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

const files = SCAN_DIRS.map((d) => path.join(ROOT, d))
  .filter((d) => existsSync(d))
  .flatMap((d) => walk(d));
const groups = cloneGroups(collectWindows(files));
// "Copies beyond the original": one group seen in fifteen files is fourteen
// pastes someone made, which is the thing being counted.
const total = groups.reduce((sum, g) => sum + g.length - 1, 0);

const mode = process.argv[2];
if (mode === "--report") report(groups, total, files.length);
else if (mode === "--update") writeBudget(total);
else enforce(groups, total);
