module

-- The syntax-linter carrier; see the note in `Template/Basic.lean`.
public import Mathlib.Tactic.Linter.DeprecatedSyntaxLinter -- shake: keep
import Mathlib.Tactic.NormNum

/-!
# Hello world

The template's one content module. Replace it with your library's first
real module; a new module must be imported by all three roots
(`Template.lean`, `Template/AxiomAudit.lean`, `TemplateTest/Gate.lean` —
the import-roots stage of `lake test` enforces this).
-/

@[expose] public section

namespace Template

/-- The hello-world theorem: `1 + 1 = 2`, closed by `norm_num`. The
coverage gate classifies it as a concrete numeric pin, so it needs no
ledger entry; delete it when your first real declaration lands. -/
theorem hello_world : (1 : ℕ) + 1 = 2 := by norm_num

end Template
