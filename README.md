# lean-self-audit-template

[![ci](https://github.com/matt-w-horn/lean-self-audit-template/actions/workflows/ci.yml/badge.svg)](https://github.com/matt-w-horn/lean-self-audit-template/actions/workflows/ci.yml)
![license: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)

A template for a Lean 4 + Mathlib library with two tiers of honesty
gates: a kernel tier that fails the build when a mechanical claim stops
being true (a `sorry`, a stray axiom, statement drift, an uncovered
declaration), and a review tier that records docstring-vs-statement
verdicts and reports when a recorded verdict goes stale under a
docstring or statement change. Fork it, run
`python3 tools/rename.py YourLib`, and replace `Template/Hello.lean`
with your first real module.

Statement locks are golden files, a familiar idea; the new parts are
the claims ledger, the coverage gate, and gates tested against
constructed evasions. This is a template rather than a Lake plugin
because the gates are project-entangled Lean and CI; a plugin can come
later.

## The gates, in two tiers

The tiers are not peers. The kernel tier is mechanical and hard-fails
the build; the review tier is calibrated human/LLM judgment whose
verdicts are recorded and re-checked, and it ships advisory.

**Kernel tier:**

- **Axiom audit** (`Template/AxiomAudit.lean`, runs in `lake build`):
  every declaration is checked against `propext`/`Classical.choice`/
  `Quot.sound`. A `sorry`, a `native_decide`, or a custom axiom fails
  the build. The audit un-mangles `private` names, and `#omitted_audit`
  checks that deliberately-omitted results are absent.
- **Statement lock** (`tests/statements.lock`, runs in `lake test`):
  every declaration's elaborated type is frozen. Removals, changes, and
  additions all fail. Regenerate deliberately with
  `lake exe templateTest --update-lock`.
- **Coverage gate** (`TemplateTest/Gate.lean`): every declaration must be
  consumed, witnessed, pinned, bridged, or ledgered with a justification.
- **Proof-token scan** (`scripts/checks.py`): the source-level backstop
  that sees what elaboration cannot, because Lean never adds an
  `example` to the environment.
- **Silencing-markers linter** (`Template/Lint.lean`, runs in
  `lake lint`): fails on any declaration carrying a gate-silencing
  marker (`unsafe`, `partial`, an `implemented_by` or `extern`
  replacement, a `nolint` exemption). The library-wide complement to the
  commit-time silencing guard, which still owns the two markers this
  linter cannot see: an in-file `set_option` (syntax, invisible to an
  environment linter) and a `nolint` exemption from this linter itself.
- **Negative fixtures** (`tests/negative/`): twelve expected-failure
  files, six that must fail to elaborate and six the source-level scan
  must reject. The gates are tested against constructed evasions, not
  assumed to bite. Each fixture is registered in `TemplateTest/Main.lean`;
  a file added to the directory and registered in neither list never runs
  (see `tests/negative/README.md`).
- **Scanner corpus** (`tests/positive/`): hazard shapes the scanner must
  produce zero findings on, so scanner changes cannot drift toward
  false positives.
- **Linter coverage**: every module must transitively import the
  syntax-linter carrier, so lakefile linter options are never silently
  inert.

**Review tier:**

- **Claims ledger** (`tests/claims.lock`): docstring-vs-statement
  verdicts, recorded only through `scripts/claims.py`, re-checked by
  hash on every `lake test` run. A verdict goes stale when the
  statement, the docstring, or a direct dependency's docstring changes.
  Ships in `advisory` mode: findings print, nothing fails, until you
  bootstrap a reviewed ledger and flip the mode. The reviewer is
  pluggable; see `claims-contract.md`. Fifteen calibration pairs ship
  in `tests/claims-calibration/`. The reviewer must author elaborating
  Lean probes, and the only configurations that have passed calibration
  to date are top-tier models (Opus 5 / Fable class or equivalent) at
  high reasoning effort. That requirement belongs to this tier alone;
  the kernel-tier gates need no model.

## Build

```sh
lake exe cache get   # prebuilt Mathlib binaries (first setup)
lake build           # library + axiom audit
lake test            # statement lock, fixtures, scans, coverage
lake lint            # environment linters
make verify          # every gate, then a stamp of the verified tree
```

`make verify` is wired as a pre-commit hook (`pre-commit install`),
alongside gitleaks, the silencing guard, and a staged-source
proof-token scan.

Outside the per-commit gates, two kernel re-checks are wired to run
weekly in CI (`.github/workflows/watchers.yml`) and on demand:
`make leanchecker` replays every module through the toolchain's own
checker (same kernel implementation and pin as the elaborator, imports
trusted), and `make nanoda` re-checks the full
[lean4export](https://github.com/leanprover/lean4export) cone, Mathlib
included, with [Nanoda](https://github.com/ammkrn/nanoda_lib), a Lean
kernel written from scratch in Rust. The case for the second
implementation is Leonardo de Moura's
[Who Watches the Provers?](https://leodemoura.github.io/blog/2026-3-16-who-watches-the-provers/):
a kernel bug replays identically in the kernel's own checker, and an
independent implementation has to be wrong in the same way at the same
time.

## Adopting the template

1. Rename `Template`/`TemplateTest` (directories, `Template.lean`, the
   names in `lakefile.toml`) to your library's name.
2. Replace `Template/Hello.lean`; register every new module in the three
   import roots (`Template.lean`, `Template/AxiomAudit.lean`,
   `TemplateTest/Gate.lean`); `lake test` enforces this.
3. Regenerate `tests/statements.lock` and replace the ledger entries in
   `TemplateTest/Ledger.lean` as your declarations land.
4. The `instantiation` CI job (layers 2-3 of the self-test) is keyed to
   the toy content and exits neutral once the project is renamed; delete
   that job and `tools/selftest.sh` when the toy module goes.

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
toward a plan. This template covers drift: statements, coverage, and
prose staying what they were verified to be. Use them together.

The gates run for real in
[Overload](https://github.com/matt-w-horn/overload), the library they
were developed in. The review tier's pluggable reviewer has a working
implementation in
[lean-skills](https://github.com/matt-w-horn/lean-skills): its
`lean-claims-review` skill dispatches the blinded referees that fill a
claims ledger like this one.

## License

Apache-2.0. See `LICENSE`.
