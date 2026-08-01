# scripts/

Checks that read source text rather than the elaborated environment,
plus the claims-review tooling.

- `checks.py`: the proof-token scan that `lake test` shells out to, over
  the library as its last stage and with `--scan FILE` over the six
  scanner fixtures and the positive corpus.
- `claims.py`: the claims ledger's only writer.
- `claim-probe.sh`: elaborates Lean read from stdin against the built
  library. It is the blinded claims review's one probe command.
- `nolints-style.txt`: the style-lint exception list.

## After a green `make verify`: the two semantic passes

The mechanical stages verify proofs, not meaning: a statement can be
wrong while everything is green. Two passes follow, scoped to
`.verify/changed_lean.txt` (written by the ritual):

1. **Soundness pass** — for each changed declaration, check the
   statement proves what you meant: hypotheses satisfiable, conclusion
   not vacuous or junk-true, side conditions where the content lives.
2. **Prose pass** — for each changed declaration, check every English
   surface naming it (docstring, README) still claims exactly what the
   statement proves; the claims ledger records the verdicts.
