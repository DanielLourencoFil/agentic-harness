# PLAN - Fire the decision rite, and make its claims anchored (2026-08-10)

Approved 2026-08-10. Persisted here because plans are permanent files, never
ephemeral plan-mode drafts (standing rule). Implemented as ADR 68 / C-171.

## Context

The goal is not a design canon (POST vs PATCH, versioning, resource modelling) and
not a track for an operator who cannot review the output. It is the repo's own
Principle 2, stated in `README.md:105`: "The harness is externalized memory. **No
check depends on me remembering to ask.**" The owner does not want to rely on his own
memory or experience for architecture and stack decisions, because his formation
carries its own vices; he wants the decision raised at the moment it is being made,
explained, and problematised, with neither party trusted on its word.

Anchored findings that make this a real gap and not a preference:

1. `home/skills/decide/SKILL.md:12-15` states the rite "triggers this rite **even
   unprompted**" for four decision classes (branching logic, module or service
   boundary crossing, a property the type system cannot verify, irreversible blast
   radius). **Nothing fires it.** Every hook wired in `home/claude/settings.json` was
   checked: backlog-inject, skill-activation, secret-scan, deliberation-nudge,
   env-dump-guard, audit-reminder, push-guard, write-containment, shelf-inventory,
   recommendation-anchor, evidence-gate. None targets a decision's shape. By the
   repo's own anti-pattern list (`PLAYBOOK.md:516-517`) that is
   "documented-but-not-wired governance ... a prayer, not a gate".
2. `deliberation-nudge.py` catches the human's *wording* ("faz sentido"), which is the
   wrong signal: it fires when he asks, not when the decision happens.
3. Layer A requires every claim to carry a verified path or command, or be labelled
   "hypothesis / not verified". `home/skills/decide/SKILL.md` step 2 asks for
   alternatives "with costs" and imposes no such label, so a cost figure recalled from
   training reads with the same authority as one measured in the repo.

The premise behind finding 3, stated plainly: "trust neither the AI nor the human"
only produces verification if the two error distributions are independent. They are
not. `README.md:106-108` says AI output is "the statistical center of its training
data - average code, including institutionalized anti-patterns", and the owner's
stated worry is that his own formation carries the vices of the same industry corpus.
Correlated biases do not audit each other. What breaks the correlation is a third
party that is not memory: a named falsifier, an exit cost measured in the repo, or a
source cited with a checked-on date.

Degree: half-force, which ADR 25's freeze admits always ("force and half-force
always"), so no exemption is needed. Constraint from ADR 14 (`PLAYBOOK.md:495-502`):
every instruction must demand a verifiable artifact; an open question with no anchor
("did you consider scalability?") is decoration the session answers to itself.

## Approach

Ordered by value over cost. Items 1 and 2 are the core; 3 and 4 are cheap
consolidation.

### 1. /decide claims carry their provenance (steer, layer-A extension)

`home/skills/decide/SKILL.md`, step 2. Scope: the rule binds **quantitative claims
only** - cost figures, scale and throughput limits, latency and performance
assertions, effort or duration estimates. Each carries either a verified anchor (a
path, a command output, a source cited with a checked-on date, matching the ADR
convention in `PLAYBOOK.md` kickoff step 2) or the explicit label "from training, not
verified". Structural claims stay free ("this option couples you to the vendor" is
verifiable by reading, and needs no anchor).

Rejected: labelling every cell of the alternatives table. If every claim carries a
label the label stops discriminating, which is the failure mode of a warning budget.

### 2. A shape-triggered nudge fires the rite (half-force)

New machine-layer hook, `home/bin/decision-nudge.py`, in the shape of
`deliberation-nudge.py`: a nudge, never a block, since shape detection is heuristic
and false positives must cost nothing.

v1 signal, deliberately one and not four (the docstring rule: "marker list grows only
from real misses, never speculatively"): a PreToolUse on `Write|Edit` whose target is
a dependency manifest (`package.json`, `pnpm-workspace.yaml`) or a deploy/infra
descriptor (`Dockerfile`, `*.tf`, `fly.toml`, `docker-compose*`). These are
mechanically detectable, carry an irreversible blast radius by `decide/SKILL.md`'s own
list, and are exactly the stack decisions that today pass with no ADR.

Rejected for v1: data migrations (`**/migrations/**`, `prisma/schema.prisma`) - also
irreversible, but tooling regenerates them, so the nudge would fire on every
regeneration and train the reader to ignore it. It enters on a real miss, not now.
Also rejected: extending `deliberation-nudge.py` with decision-shaped prompt markers -
cheaper, but it re-arms on the owner's wording, which is the very dependency this item
exists to remove.

### 3. Exit cost named in the recommendation (steer)

`home/skills/decide/SKILL.md`, step 4: the recommendation states what undoing the
decision costs and the last cheap moment to undo it. This is the one architecture
heuristic with an objective test (can it be undone in one focused session?), and it
yields "a solo maintainer should not open on microservices" as an output of the
project's facts rather than as canon that ages.

### 4. Operator profile as an interview input (steer, consolidation)

`home/skills/greenfield/SKILL.md` step 1 and `PLAYBOOK.md` SPEC INTERVIEW: one
question, phrased by capacity not identity - who maintains this after v1, who is on
call and what they can operate, the monthly budget ceiling, what must survive a
provider change. This consolidates a variable already used ad hoc in three places
(`PLAYBOOK.md:204`, `:284`, `:365`) and feeds items 1 and 3 with real constraints.

## Explicitly out of scope

- **No canon of design or stack table.** Quality-doctrine steer, frozen by ADR 25, and
  the shape ADR 42 measured below the sweep's own adoption floor. The AI supplies the
  explanation at the moment of the decision, against this project's facts; the harness
  supplies the trigger and the format.
- **No block.** Every mechanism here is a nudge plus an existing human gate.

## Declared limits

- The nudge fires on file shape, so a stack decision taken without touching one of
  those files is missed entirely.
- Whether a "verified" label is honest stays judgment; nothing checks it.
- The exit-cost estimate is itself a quantitative claim, and the rite asks for it in
  the same breath as it distrusts such claims. It is bound by item 1's rule.
