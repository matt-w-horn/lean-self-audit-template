# Lean formalization template

A template for a Lean 4 + Mathlib library with two tiers of honesty
gates: a kernel tier that fails the build when a mechanical claim stops
being true (a `sorry`, a stray axiom, statement drift, an uncovered
declaration), and a review tier that records docstring-vs-statement
verdicts and reports when a recorded verdict goes stale under a
docstring or statement change. Fork it, run
`python3 tools/rename.py YourLib`, and replace `Template/Hello.lean`
with your first real module.

Two clarifications up front. Statement locks are golden files — the new
parts are the claims ledger, the coverage gate, and gates tested
against constructed evasions. And this is a template rather than a Lake
plugin because the gates are project-entangled Lean and CI; a plugin
can come later.

## The gates, in two tiers

The tiers are not peers. The kernel tier is mechanical and hard-fails
the build; the review tier is calibrated human/LLM judgment whose
verdicts are recorded and re-checked, and it ships advisory.

**Kernel tier — mechanical, hard-fail:**

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
- **Proof-token scan** (`scripts/checks.py`): the source-level backstop
  that sees what elaboration cannot, because Lean never adds an
  `example` to the environment.
- **Negative fixtures** (`tests/negative/`): ten expected-failure files,
  five per gate family — the gates are tested against constructed
  evasions, not assumed to bite.
- **Scanner corpus** (`tests/positive/`): hazard shapes the scanner must
  produce zero findings on, so scanner changes cannot drift toward
  false positives.
- **Linter coverage**: every module must transitively import the
  syntax-linter carrier, so lakefile linter options are never silently
  inert.

**Review tier — calibrated, evidence-carrying, advisory:**

- **Claims ledger** (`tests/claims.lock`): docstring-vs-statement
  verdicts, recorded only through `scripts/claims.py`, re-checked by
  hash on every `lake test` run. A verdict goes stale when the
  statement, the docstring, or a direct dependency's docstring changes.
  Ships in `advisory` mode: findings print, nothing fails, until you
  bootstrap a reviewed ledger and flip the mode. The reviewer is
  pluggable — see `claims-contract.md`. Calibration pairs ship in
  `tests/claims-calibration/`.

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

## What routine changes cost

- **A statement change** is deliberate by design: the lock fails, you
  re-record with `lake exe templateTest --update-lock`, and any claims
  rows over the changed statements go stale (re-review or re-record
  them through `scripts/claims.py`).
- **A Mathlib bump** rebuilds the world and re-elaborates every
  statement; where printed types shift, the lock diff is your exact
  review list.
- **Escape hatches are open by design**: `SKIP=verify git commit` and
  `--no-verify` skip the pre-commit ritual; a skipped verify means run
  `make verify` afterward, and the staged-source proof-token scan still
  runs either way.

## Beside the neighbors

[LeanProject](https://github.com/pitmonticone/LeanProject) covers
project setup, build, and publishing; blueprint tooling covers progress
toward a plan. This template covers drift — statements, coverage, and
prose staying what they were verified to be. Use them together.

## License

Apache-2.0. See `LICENSE`.
