module

import all Template.Basic
import all Template.Hello
import all Template.Lint
import all Template.AxiomAudit

public meta import Lean.Elab.Command
public meta import TemplateTest.Coverage
public import TemplateTest.Coverage

/-!
# The coverage gate

Elaborating this file runs the coverage report over the whole library, so
`lake test` (which builds the test driver, which imports this) fails on any
uncovered declaration. The class tally lands in the build log next to the
axiom audit's count.

The `#coverage_report` elaborator is defined here rather than in
`TemplateTest/Coverage.lean` because the helpers it reads serve two phases:
the test driver executable calls them at runtime, so they cannot be `meta`,
and a command elaborator cannot call same-module non-`meta` code — the
`meta import` of `Coverage` is what lifts them across. The library
imports are `import all`, one per module, because the consumption
graph walks proof bodies (`getUsedConstantsAsSet`) and anything less
strips them: an exported-level import replaces a theorem with a
signature stub, and `import all` does not propagate through the
`Template` aggregator — resolved either of those ways, every bridge
entry reads as stale. The list is hand-maintained like the two audit
roots; the `import-roots` stage checks all three.
-/

@[expose] public section

meta section

open Lean Elab Command in
/-- `#coverage_report Template` fails elaboration unless every non-exempt
declaration under the namespace is bridged, witnessed, consumed, or ledgered
terminal. Prints the class tally so coverage is a build-log fact. See the
module docstring for the classes and the ledgers in `TemplateTest.Ledger`. -/
elab "#coverage_report " pfx:ident : command => do
  let env ← getEnv
  let root := pfx.getId
  -- The graph and classification are `TemplateTest.computeCoverage` in
  -- `TemplateTest/Coverage.lean` — one code path with the manifest
  -- stamping. This elaborator's whole job is turning its findings into
  -- errors and printing the tally.
  let cov := TemplateTest.computeCoverage env root
  if cov.univ.isEmpty then
    throwError "#coverage_report: no declarations found under `{root}`"
  if let some f := cov.findings[0]? then
    throwError "#coverage_report: {f}"
  let acc := cov.tally
  let total := cov.univ.size
  let pct (k : Nat) : Nat := k * 100 / total
  unless acc.uncovered.isEmpty do
    let names := acc.uncovered.qsort (·.toString < ·.toString)
    throwError "#coverage_report: {acc.uncovered.size} uncovered (C0) declaration(s) under \
      `{root}`:{indentD (MessageData.joinSep (names.toList.map (m!"{·}")) Format.line)}"
  logInfo m!"#coverage_report: {total} declarations under `{root}` — \
    C4 bridged {acc.c4} ({pct acc.c4}%), C3 pinned {acc.c3} ({pct acc.c3}%), \
    C2 witnessed {acc.c2} ({pct acc.c2}%), C1 consumed {acc.c1} ({pct acc.c1}%), \
    terminal {acc.t} ({pct acc.t}%), C0 uncovered 0 \
    (exempt auto-generated: {cov.exempt})"

end

#coverage_report Template
