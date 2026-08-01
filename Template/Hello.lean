module

-- The syntax-linter carrier; see the note in `Template/Basic.lean`.
public import Mathlib.Tactic.Linter.DeprecatedSyntaxLinter -- shake: keep
import Mathlib.Tactic.Ring

/-!
# Hello world

The template's one content module: a four-declaration toy lattice that
gives every coverage class a live example — a consumed `def`, a consumed
theorem, a numeric pin, and a ledgered terminal entry. Replace it with
your library's first real module; a new module must be imported by all three roots
(`Template.lean`, `Template/AxiomAudit.lean`, `TemplateTest/Gate.lean` —
the import-roots stage of `lake test` enforces this).
-/

@[expose] public section

namespace Template

/-- Doubling as repeated addition: the toy definition. `double_eq_two_mul`
consumes it, which is what covers it (class C1, consumed). -/
def double (n : ℕ) : ℕ := n + n

/-- Doubling is multiplication by two. Consumes `double`; itself consumed
by `hello_world`'s proof, so both are covered without ledger entries. -/
theorem double_eq_two_mul (n : ℕ) : double n = 2 * n := by
  unfold double
  ring

/-- The hello-world pin: `double 1 = 2`. A concrete numeric statement, so
the coverage gate classifies it as a pin (class C3) with no ledger entry.
Numeric pins double as regression tests. -/
theorem hello_world : double 1 = 2 := by
  rw [double_eq_two_mul]

/-- `double` unfolded at its definition. Nothing consumes it and it is
`rfl`, so a consuming pin restates it: the shape that earns a terminal
ledger entry (`TemplateTest/Ledger.lean`) with a one-line justification. -/
theorem double_self (n : ℕ) : double n = n + n := rfl

end Template
