module

public import Lean

/-!
# Coverage ledgers

The two hand-maintained inputs to `#coverage_report` (TemplateTest/Coverage.lean).
Both are honesty surfaces: an entry asserts something the graph cannot see, and
the report throws when an entry goes stale (a terminal entry that gains a
consumer, witness, or pin; a name that no longer exists; a bridge whose theorem
does not depend on its target), so the ledgers cannot silently rot.
-/

@[expose] public section

namespace TemplateTest

/-- Declarations that are deliverables or pins consumed by nothing: the library
proves them *for the reader* (billed in a prose surface) or *about a
definition* (a sanity, range, eval, or reduction pin), not for another proof.
Each entry carries a one-line justification; "billed in X" names the prose
surfaces citing it. An entry that becomes consumed, witnessed, or pinned fails
the report — delete the entry, the coverage got stronger.
 -/
def terminalLedger : List (Lean.Name × String) :=
  [
    (`Template.double_self, "eval pin at the definition; rfl, so a consuming pin restates it — the template's worked example of a terminal entry"),
    (`Template.docBlameThmEnabled, "enabled registration of Batteries' docBlameThm; consumed by runLinter through the env_linter attribute at lint time, not by any proof"),
    (`Template.explicitVarsOfIffEnabled, "enabled registration of Batteries' explicitVarsOfIff; consumed by runLinter through the env_linter attribute at lint time, not by any proof"),
  ]

/-- Pairs `(target, bridge)`: `bridge` proves `target` equivalent to (or
consistent with) an independent formulation, so `target` is verified beyond
its own statement. The report checks that `bridge` actually depends on
`target`. -/
def bridgedLedger : List (Lean.Name × Lean.Name) :=
  []

end TemplateTest
