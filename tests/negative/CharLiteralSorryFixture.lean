module

import Template.Basic

/-! A char literal containing a double quote (`'"'`) desynchronized the
scanner's string tracking: everything after it read as string content, so
the `--` looked like a comment opener was irrelevant and the real `sorry`
at the end of the line was invisible (exit 0, demonstrated before the
fix). The fixture compiles — a term-level `sorry` is a warning — and the
source-level proof-token scan must reject it. -/

example : Char × (String × Nat) := ('"', ("a -- b", (sorry : Nat)))
