# Lean formalization template

A template for a Lean 4 + Mathlib library whose build fails when its
honesty claims stop being true. Fork it, rename `Template` to your
library's name, and replace `Template/Hello.lean` with your first real
module.

## What the harness checks

- **Axiom audit** (`Template/AxiomAudit.lean`, runs in `lake build`):
  every declaration is checked against `propext`/`Classical.choice`/
  `Quot.sound`. A `sorry`, a `native_decide`, or a custom axiom fails
  the build. The audit un-mangles `private` names, and `#omitted_audit`
  checks that deliberately-omitted results are actually absent.
- **Statement lock** (`tests/statements.lock`, runs in `lake test`):
  every declaration's elaborated type is frozen. Removals, changes, and
  additions all fail. Regenerate deliberately with
  `lake exe templateTest --update-lock`.
- **Coverage gate** (`TemplateTest/Gate.lean`): every declaration must be
  consumed, witnessed, pinned, bridged, or ledgered with a justification.
- **Negative fixtures** (`tests/negative/`): ten expected-failure files.
  Five must fail to elaborate. Five compile and must be caught by the
  source-level proof-token scan — the gate that sees what elaboration
  cannot, because Lean never adds an `example` to the environment.
- **Scanner corpus** (`tests/positive/`): hazard shapes the scanner must
  produce zero findings on, so scanner changes cannot drift toward
  false positives.
- **Claims ledger** (`tests/claims.lock`, advisory until you bootstrap):
  blinded docstring-vs-statement verdicts, recorded only through
  `scripts/claims.py`. Calibration pairs ship in
  `tests/claims-calibration/`.
- **Linter coverage**: every module must transitively import the
  syntax-linter carrier, so lakefile linter options are never silently
  inert.

## Build

```sh
lake exe cache get   # prebuilt Mathlib binaries (first setup)
lake build           # library + axiom audit
lake test            # statement lock, fixtures, scans, coverage
lake lint            # environment linters
make verify          # every gate, then a stamp of the verified tree
```

`make verify` is wired as a pre-commit hook (`pre-commit install`),
alongside gitleaks and a staged-source proof-token scan.

## Adopting the template

1. Rename `Template`/`TemplateTest` (directories, `Template.lean`, the
   names in `lakefile.toml`) to your library's name.
2. Replace `Template/Hello.lean`; register every new module in the three
   import roots (`Template.lean`, `Template/AxiomAudit.lean`,
   `TemplateTest/Gate.lean`) — `lake test` enforces this.
3. Regenerate `tests/statements.lock` and replace the ledger entries in
   `TemplateTest/Ledger.lean` as your declarations land.

## License

Apache-2.0. See `LICENSE`.
