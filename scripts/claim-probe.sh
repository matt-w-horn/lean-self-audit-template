#!/bin/sh
# The blinded claim referee's only command: elaborate Lean source from
# stdin against the built library and its dependencies. Exit 0 iff
# elaboration succeeds, so `#check`, `example`, and tactic probes can
# distinguish provable from not. No file access, no other tools — the
# blinding contract (claims-contract.md at the repo root) is that a
# reviewer reaches the formal environment and nothing textual.
cd "$(dirname "$0")/.." || exit 2
exec lake env lean --stdin "$@"
