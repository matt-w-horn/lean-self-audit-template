# tests/

- `statements.lock`: the statement freeze. Every hand-written
  declaration's elaborated type, with value hashes for definition kinds.
  Only `lake exe templateTest --update-lock` regenerates it.
- `claims.lock`: docstring-vs-statement verdicts with the hashes they
  were judged at.
- `negative/`: eleven expected-failure fixtures. Five must fail to
  elaborate. The other six compile, and the proof-token scan must reject
  them.
- `positive/`: `ScannerCorpus.lean`, hazard shapes the scanner must
  produce zero findings on.
- `claims-calibration/`: fifteen (statement, docstring) pairs with an
  answer key: nine constructed defects, five known-good pairs, and one
  ambiguous. A referee configuration must match the key on all fifteen.
