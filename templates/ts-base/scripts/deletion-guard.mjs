// Blocks a commit that deletes more than LIMIT lines, unless ALLOW_BIG_DELETE=1.
// A brake against the agent silently gutting working code.
import { execSync } from "node:child_process";

const LIMIT = 80;
const diff = execSync("git diff --cached --numstat", { encoding: "utf8" });

let deleted = 0;
for (const line of diff.split("\n")) {
  const [, del, file] = line.split("\t");
  if (!file || file.includes("lock")) continue; // ignore lockfiles
  const n = Number(del);
  if (!Number.isNaN(n)) deleted += n;
}

if (deleted > LIMIT && process.env.ALLOW_BIG_DELETE !== "1") {
  console.error(
    `❌ Deletion guard: ${deleted} lines deleted (limit ${LIMIT}).\n` +
      `   Set ALLOW_BIG_DELETE=1 if this is intentional.`,
  );
  process.exit(1);
}
