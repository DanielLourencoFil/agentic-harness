// Stranded-logic budget.
//
// The rule "pure logic lives in src/lib, components render" (AGENTS.md) is steer:
// nothing stops a pure function from being written inside a .tsx renderer, where
// it can only be tested by mounting the component. `max-lines` catches the gross
// case (a 2000-line component is uncommittable) and mutation rewards lib
// placement, but a small pure function stranded in a small component slips both,
// and human review does not scale against AI-produced volume.
//
// So this counts the result, the same shape as the copy-paste budget: a
// module-scope function in a .tsx file with no JSX, no hooks, no setState and no
// impure globals is pure logic in the wrong place. The count is a budget, and the
// budget may only fall. New stranded logic raises it and fails the build; moving
// a function to src/lib lowers it.
//
// Heuristic, deliberately: it reports candidates, not a verdict. False positives
// exist (a large Zod schema built next to its form reads as pure), and they are
// handled exactly as the clone budget handles its noise — baselined in, so only
// NET NEW stranded logic fails. A false positive that is genuinely fine is raised
// into the budget in the same commit, where a reviewer sees the reason, like a
// deliberate clone.
//
// Scope: .tsx only (React components). Vue's .vue single-file components need the
// <script> block extracted first and are a declared follow-up, not covered here.
//
// Usage:
//   node scripts/stranded-logic-check.mjs            check against .strandedbudget.json
//   node scripts/stranded-logic-check.mjs --report   list the stranded functions
//   node scripts/stranded-logic-check.mjs --update    write the current count as budget
import { execSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

const ROOT = path.join(import.meta.dirname, "..");
const BUDGET_FILE = path.join(ROOT, ".strandedbudget.json");
const SCAN_DIRS = ["src", "app", "apps", "packages"];
const SKIP_DIRS = new Set(["node_modules", ".next", "dist", "build", "coverage"]);

// A body touching these is I/O or non-determinism, not pure logic: it drops the
// canvas / storage / clock / network false positives a bare "no JSX, no hooks"
// scan admits (measured against the calendar-app scan, which flagged a canvas
// exporter as pure).
const IMPURE =
  /\b(document|window|localStorage|sessionStorage|fetch|canvas|navigator|crypto|Date\.now|Math\.random|process\.env)\b/;

const DECL =
  /^(?:export\s+)?(?:async\s+)?(?:function\s+([a-zA-Z_$][\w$]*)\s*\(|const\s+([a-zA-Z_$][\w$]*)\s*(?::[^=]+)?=\s*(?:async\s*)?\()/;

function walk(dir, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) walk(full, out);
    } else if (/\.tsx$/.test(entry.name) && !/\.test\.tsx$/.test(entry.name)) {
      out.push(full);
    }
  }
  return out;
}

/** The function body from its declaration line, by brace balance, and its last
 *  line. Capped at 200 lines so a runaway brace never hangs the gate. */
function readBody(lines, start) {
  let depth = 0;
  let started = false;
  let body = "";
  let end = start;
  for (let j = start; j < Math.min(lines.length, start + 200); j++) {
    body += lines[j] + "\n";
    for (const ch of lines[j]) {
      if (ch === "{") {
        depth++;
        started = true;
      } else if (ch === "}") depth--;
    }
    end = j;
    if (started && depth <= 0) break;
    // Expression-body form (an arrow returning an expression, no block): the
    // statement ends at the first `;` at depth 0, before any `{` opens. Without
    // this, a brace-free arrow one-liner runs the walker on to the next unrelated
    // `{...}`, swallowing sibling code and inflating a 1-line body past the
    // `< 4` one-liner filter (found by ultrareview; ADR 44).
    if (!started && depth === 0 && /;\s*$/.test(lines[j])) break;
  }
  return { body, end };
}

/** A body that renders, uses a hook, sets state, or touches I/O is not the pure
 *  logic this gate is looking for. */
function looksImpure(body) {
  return (
    /<[A-Za-z][\w.]*[\s/>]/.test(body) ||
    /\buse[A-Z]\w*\s*\(/.test(body) ||
    /\bset[A-Z]\w*\s*\(/.test(body) ||
    IMPURE.test(body)
  );
}

/** Module-scope functions in one .tsx file that look like pure logic. */
function strandedIn(file) {
  const lines = readFileSync(file, "utf8").split("\n");
  const found = [];
  for (let i = 0; i < lines.length; i++) {
    const match = DECL.exec(lines[i]);
    const name = match ? match[1] || match[2] : "";
    // A capitalised name is a component by convention, not stranded logic.
    if (!name || /^[A-Z]/.test(name)) continue;
    const { body, end } = readBody(lines, i);
    // One-liners are not worth moving; the noise would drown the signal.
    if (looksImpure(body) || end - i + 1 < 4) continue;
    found.push({ file: path.relative(ROOT, file), line: i + 1, name });
  }
  return found;
}

function touchedFiles() {
  const opts = { cwd: ROOT, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] };
  const run = (cmd) => {
    try {
      return execSync(cmd, opts).split("\n");
    } catch {
      return [];
    }
  };
  return new Set(
    [
      ...run("git diff --relative --name-only HEAD"),
      ...run("git diff --relative --cached --name-only"),
      ...run("git ls-files --others --exclude-standard"),
    ]
      .map((l) => l.trim())
      .filter(Boolean),
  );
}

const stranded = SCAN_DIRS.map((d) => path.join(ROOT, d))
  .filter((d) => existsSync(d))
  .flatMap((d) => walk(d))
  .flatMap(strandedIn);
const total = stranded.length;

const mode = process.argv[2];

if (mode === "--report") {
  console.log(`🔍 ${total} pure-logic functions stranded in .tsx files\n`);
  for (const s of stranded) console.log(`   ${s.file}:${s.line}  ${s.name}`);
} else if (mode === "--update") {
  writeFileSync(
    BUDGET_FILE,
    `${JSON.stringify(
      {
        maxStranded: total,
        updatedAt: new Date().toISOString().slice(0, 10),
        note: "Module-scope pure functions in .tsx files, counted by scripts/stranded-logic-check.mjs. This number may go down, never up. Move logic to src/lib to lower it; raise it deliberately only for a genuine false positive.",
      },
      null,
      2,
    )}\n`,
  );
  console.log(`✅ Stranded-logic budget written: ${total}`);
} else {
  if (!existsSync(BUDGET_FILE)) {
    console.error(
      "❌ .strandedbudget.json not found. Create it: node scripts/stranded-logic-check.mjs --update",
    );
    process.exit(1);
  }
  const max = JSON.parse(readFileSync(BUDGET_FILE, "utf8")).maxStranded;
  if (total <= max) {
    const hint = total < max ? " — ratchet it down: --update" : `/${max}`;
    console.log(`✅ Stranded-logic budget: ${total}${hint}`);
  } else {
    const touched = touchedFiles();
    const mine = stranded.filter((s) => touched.has(s.file));
    const shown = mine.length > 0 ? mine : stranded;
    console.error(`\n❌ Stranded-logic budget exceeded: ${total} > ${max}`);
    console.error(
      mine.length > 0
        ? "   Pure logic you added inside a .tsx renderer:\n"
        : "   Could not tell which are new; the stranded functions:\n",
    );
    for (const s of shown.slice(0, 10)) console.error(`   ${s.file}:${s.line}  ${s.name}`);
    console.error(
      "\n   Move it to src/lib, where it is testable without a renderer and mutation defends it.",
    );
    console.error(
      "   If it genuinely belongs here (e.g. a schema next to its form), raise the budget in the same commit.",
    );
    process.exit(1);
  }
}
