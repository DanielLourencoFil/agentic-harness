// Clone detection: the measuring half of the copy-paste budget. Kept apart from
// scripts/clone-budget-check.mjs, which decides what to DO with the number —
// read a budget, scope a failure to the author, exit non-zero. The split was not
// aesthetic: the combined file crossed the template's own max-lines cap, which
// is the rule doing its job on the tooling too.
import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";

/** Coercing silently disabled the gate: CLONE_WINDOW_LINES=nope gave NaN, every
 *  window comparison went false, and the run reported a clean 0 and exit 0 — a
 *  gate switched off by a typo (audit 2026-07-30). */
export function intFromEnv(name, fallback, min) {
  const raw = process.env[name];
  if (raw === undefined || raw === "") return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min) {
    console.error(
      `❌ ${name} must be an integer >= ${String(min)}, got ${JSON.stringify(raw)}`,
    );
    process.exit(1);
  }
  return value;
}

/**
 * A window this long is a clone. Measured, not picked — on the repo that
 * motivated this gate (calendar-app, 2026-07-29): at 8 the 15× matchMedia block
 * that justified it is found (553 groups / 753 copies); at 10 and 12 it is
 * missed (317/405 and 211/259). The block is eight significant lines long, so a
 * longer window is quieter and blind to exactly the case it exists for.
 *
 * Override with CLONE_WINDOW_LINES to explore; the budget records the window it
 * was measured at, and enforcing across a mismatch is refused.
 */
export const WINDOW_LINES = intFromEnv("CLONE_WINDOW_LINES", 8, 1);

const SKIP_DIRS = new Set(["node_modules", "dist", "build", "coverage"]);

/** Tests repeat their arrange blocks by nature (AGENTS.md prefers that to clever
 *  shared helpers), and generated files are written by no one. Neither is a
 *  copy-paste anybody should answer for. */
const SKIP_FILE = /\.(spec|test)\.tsx?$|\.d\.ts$/;
const SOURCE_FILE = /\.tsx?$/;

/** Sorted: readdirSync order is filesystem-dependent, and both the greedy
 *  overlap-collapse below and its tie-break read it, so an unsorted walk let the
 *  same source count differently on two machines — a red build here and a green
 *  one there (audit 2026-07-30). */
const byName = (a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0);

function walk(dir, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true }).sort(byName)) {
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
 *  signal in noise nobody can act on. The quote after `from` matters: matching a
 *  bare `\bfrom\b` also dropped `export const url = "https://x/from/y"`. */
const isNoise = (line) => /^(import|export)\b[^;]*\bfrom\s+["']/.test(line);

/**
 * The comment-free part of one line, carrying `state.inComment` across lines.
 *
 * Character-level, because line-level was wrong in both directions. A line that
 * opened AND closed a block comment before real code was discarded whole,
 * losing that code: an 8-line paste then measured 7 significant lines and
 * slipped under the window. And a block comment OPENED mid-line was never
 * tracked, so its prose was hashed as logic and duplicated comments were charged
 * to the budget. Both found by audit 2026-07-30.
 *
 * Declared limit: comment markers inside string literals are not understood.
 * Telling them apart needs a real parser, a dependency this gate does not
 * justify; the effect is confined to lines carrying such literals.
 */
function stripComments(rawLine, state) {
  let out = "";
  let i = 0;
  while (i < rawLine.length) {
    if (state.inComment) {
      const end = rawLine.indexOf("*/", i);
      if (end === -1) return out;
      state.inComment = false;
      i = end + 2;
      continue;
    }
    const block = rawLine.indexOf("/*", i);
    const line = rawLine.indexOf("//", i);
    if (line !== -1 && (block === -1 || line < block)) {
      return out + rawLine.slice(i, line);
    }
    if (block === -1) return out + rawLine.slice(i);
    out += rawLine.slice(i, block);
    state.inComment = true;
    i = block + 2;
  }
  return out;
}

/** Lines that carry logic, with their original line numbers. */
function significantLines(source) {
  const kept = [];
  const state = { inComment: false };
  source.split("\n").forEach((raw, index) => {
    const code = stripComments(raw, state).trim();
    if (!code || isNoise(code)) return;
    // Collapse internal whitespace so reformatting cannot hide a clone.
    kept.push({ text: code.replace(/\s+/g, " "), line: index + 1 });
  });
  return kept;
}

function collectWindows(files, root) {
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
        file: path.relative(root, file),
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
 *
 * The ordering is a total order and locale-independent: `localeCompare` varies
 * with ICU data, and a tie-break on the first occurrence's file alone still
 * depended on walk order, so the same source could count differently twice.
 */
function cloneGroups(byHash) {
  const rank = (o) => `${o.file}:${String(o.startLine).padStart(9, "0")}`;
  const candidates = [...byHash.values()]
    .filter((occurrences) => occurrences.length > 1)
    .map((occurrences) => [...occurrences].sort((x, y) => (rank(x) < rank(y) ? -1 : 1)))
    .sort((a, b) =>
      b.length === a.length
        ? rank(a[0]) < rank(b[0])
          ? -1
          : 1
        : b.length - a.length,
    );

  /** file → array of [start, end] already claimed */
  const covered = new Map();
  const isCovered = (o) =>
    (covered.get(o.file) ?? []).some(
      ([start, end]) => o.startLine <= end && o.endLine >= start,
    );

  const groups = [];
  for (const occurrences of candidates) {
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

/**
 * Every clone group under `dirs`, plus the count that is the budget.
 *
 * "Copies beyond the original": one group seen in fifteen files is fourteen
 * pastes someone made, which is the thing being counted.
 */
export function findClones(dirs, root) {
  const files = dirs.flatMap((dir) => walk(dir));
  const groups = cloneGroups(collectWindows(files, root));
  return {
    groups,
    total: groups.reduce((sum, group) => sum + group.length - 1, 0),
    fileCount: files.length,
  };
}
