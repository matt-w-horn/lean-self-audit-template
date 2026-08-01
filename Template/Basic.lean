module

-- The syntax-linter carrier (Mathlib's `Mathlib.Init` pattern): linters
-- only run in modules that transitively import them, so every module must
-- reach this import or the lakefile's linter options are silently inert
-- there. The test driver's linter-coverage stage enforces the closure.
public import Mathlib.Tactic.Linter.DeprecatedSyntaxLinter -- shake: keep

/-!
# Template — shared conventions

A template library carrying a verification harness: build-time axiom audit,
statement lock, coverage gate, negative fixtures, source-level proof-token
scans, and a claims ledger. Replace this paragraph with what your library
formalizes.

Conventions the harness assumes:

* Zero `sorry`, zero custom axioms. Results that need unformalized analysis
  are omitted, not axiomatized. `Template/AxiomAudit.lean` enforces the
  axiom budget at build time.
* Every module transitively imports the syntax-linter carrier (the import
  above), so the lakefile's linter options are never silently inert. The
  test driver's linter-coverage stage checks the closure.
-/

@[expose] public section

namespace Template

end Template
