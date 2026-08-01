# The claims contract

The review tier is pluggable. Any reviewer — a human, an LLM referee, a
script — that honors this contract implements it: read pairs from the
manifest, judge blind, and write the ledger only through
`scripts/claims.py`. This file is the normative spec of the three
interfaces.

## The manifest (`.verify/manifest.json`)

Written by the test driver (`TemplateTest/Main.lean`) on every
`lake test` / `make verify` run; never hand-edited. A JSON array, one
entry per declaration under the library namespace:

| Field | Meaning |
|---|---|
| `name` | Fully-qualified declaration name |
| `module` | The module that declares it |
| `kind` | `theorem`, `def`, and the other declaration kinds |
| `type` | The pretty-printed **elaborated** statement (binders resolved) |
| `doc` | The docstring, verbatim; absent when the declaration has none |
| `statementHash` | Hash of `type` |
| `docHash` | Hash of `doc` |
| `contextHash` | Hash over the docstrings of the declaration's direct dependencies, as a reviewer would receive them |
| `valueHash` | For definition kinds: hash of the value, so body changes are visible |
| `terminal` | True when the declaration is ledgered terminal |
| `class` | The coverage class the gate assigned |

Hashes are computed only in Lean, by the driver. Nothing else
re-implements them; a reviewer treats them as opaque tokens.

## The ledger (`tests/claims.lock`)

Row format, sorted by name, one per line:

```
name | statementHash | docHash | contextHash | verdict | date [| note]
```

A `mode:` line precedes the rows: `advisory` (findings print, nothing
fails — the shipped default) or `failing` (a missing or stale row fails
`lake test`). A row is **stale** when any of its three hashes disagrees
with the manifest — that is, when the statement, the docstring, or a
direct dependency's docstring has changed since the verdict.

The only writer is `scripts/claims.py record NAME VERDICT`, which
copies the three hashes from the manifest at record time. The writer
accepts two verdicts: `supported` (a reviewer judged the docstring to
claim exactly what the statement proves) and `accepted` (the maintainer
overruled a reviewer; `--note` required). Everything else a review can
conclude routes to a fix, not to the ledger.

## The probe (`scripts/claim-probe.sh`)

The blinded reviewer's one tool: Lean source on stdin, elaborated
against the built library. Exit code 0 iff elaboration succeeds, so
`#check`, `example`, and tactic probes distinguish provable from not.
The blinding contract: a reviewer reaches the formal environment and
nothing textual — no file access, no source tree, no docs beyond the
pair under judgment and its verified dependency docstrings.

## The reviewer's verdict vocabulary

A calibrated reviewer reports one of five verdicts per pair. Only the
first reaches the ledger; the rest carry evidence to a repair:

| Verdict | Meaning | Routed to |
|---|---|---|
| `supported` | The docstring claims exactly what the statement proves | The ledger, via `claims.py` |
| `prose-overclaims` | The prose says more (axis + quoted evidence) | A docstring fix |
| `prose-underclaims` | The prose says less, specifically enough to mislead | A docstring fix |
| `statement-suspect` | A probe indicts the statement itself | The maintainer — statement changes are deliberate |
| `intent-unclear` | Two substantive readings; probes cannot arbitrate | The maintainer |

Calibrate before trusting: `tests/claims-calibration/` ships fifteen
(statement, docstring) pairs with an answer key. A reviewer
configuration must flag every constructed defect with the keyed verdict
and answer the ambiguous pair `intent-unclear` before its verdicts on
real pairs count.

## Bootstrapping

Review in dependency order (the manifest's `contextHash` is over
*direct dependencies'* docstrings, so verified context accumulates
bottom-up), record `supported` verdicts as they land, and flip
`mode: advisory` to `mode: failing` when the sweep completes. From then
on, every statement or docstring change that touches a verdicted pair
is visible in `lake test` until re-reviewed.
