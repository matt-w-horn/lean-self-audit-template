#!/bin/sh
# The template's credibility core, three layers:
#   1. the template builds green as its own instance (the normal CI build);
#   2. an instantiated copy — renamed with tools/rename.py — still builds
#      green and passes every gate;
#   3. in the instantiated copy, three injected defects are each REJECTED
#      by the responsible gate. Gates that pass green but no longer bite
#      are the failure mode this template exists to prevent.
# Layers 2 and 3 run here; layer 1 is the ordinary build this script
# assumes has already happened.
set -eu
SRC=$(cd "$(dirname "$0")/.." && pwd)
# The layers below are keyed to the template's own toy content (the
# Hello module, its lock rows, its docstrings). In an adopted project —
# anything renamed away from Template — they would be permanently red,
# so the script exits neutral there. Delete the CI job (ci.yml:
# instantiation) and this script once your own modules replace the toy
# library; until then the neutral exit keeps CI green.
NAME=$(sed -n 's/^name = "\(.*\)"$/\1/p' "$SRC/lakefile.toml" | head -1)
if [ "$NAME" != "Template" ]; then
  echo "selftest: project is '$NAME', not Template — the layer-2/3 self-test is keyed to the template's toy content; exiting neutral (delete the instantiation CI job and tools/selftest.sh in adopted projects)."
  exit 0
fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
COPY="$WORK/instance"
mkdir -p "$COPY"
# rsync may be absent on minimal runners; tar copy excludes the heavy dirs.
(cd "$SRC" && tar -cf - --exclude .git --exclude .lake --exclude .verify .) | (cd "$COPY" && tar -xf -)
cd "$COPY"

echo "== layer 2: instantiate as 'Renamed' and re-run the gates"
python3 tools/rename.py Renamed
test -f Renamed/Hello.lean
lake exe cache get >/dev/null 2>&1
lake build
lake test
echo "layer 2 PASS: renamed instance builds green and passes the gates"

echo "== layer 3a: an injected sorry must fail the build"
cp Renamed/Hello.lean "$WORK/hello.bak"
# The injected name must be rooted in the audited namespace: the audit
# sweeps `Renamed.*`, and a root-level sorry is instead caught by the
# --wfail build and the source-level proof-token scan.
printf '\n/-- Injected by selftest: must be rejected. -/\ntheorem Renamed.bad_sorry : 2 + 2 = 4 := by sorry\n' >> Renamed/Hello.lean
if lake build >"$WORK/3a.log" 2>&1; then
  echo "layer 3a FAIL: the audit accepted a sorry"; exit 1
fi
grep -q 'axiom budget exceeded.*sorryAx' "$WORK/3a.log" || { echo "layer 3a FAIL: build failed for another reason"; cat "$WORK/3a.log"; exit 1; }
cp "$WORK/hello.bak" Renamed/Hello.lean
echo "layer 3a PASS: sorry rejected"

echo "== layer 3b: a doctored statement-lock line must fail lake test"
cp tests/statements.lock "$WORK/lock.bak"
python3 - <<'PY'
from pathlib import Path
p = Path("tests/statements.lock")
lines = p.read_text().splitlines(keepends=True)
for i, l in enumerate(lines):
    if "hello_world" in l:
        lines[i] = l.replace("hello_world", "hello_world_doctored", 1)
        break
else:
    raise SystemExit("selftest: no hello_world row to doctor")
p.write_text("".join(lines))
PY
if lake test >"$WORK/3b.log" 2>&1; then
  echo "layer 3b FAIL: the lock accepted a doctored line"; exit 1
fi
grep -q 'FAIL \[lock\]' "$WORK/3b.log" || { echo "layer 3b FAIL: test failed for another reason"; cat "$WORK/3b.log"; exit 1; }
cp "$WORK/lock.bak" tests/statements.lock
echo "layer 3b PASS: doctored lock rejected"

echo "== layer 3c: a docstring edit under a recorded verdict must go stale"
lake test >/dev/null 2>&1   # green run regenerates the manifest
python3 scripts/claims.py record Renamed.hello_world supported
python3 - <<'PY'
from pathlib import Path
p = Path("Renamed/Hello.lean")
t = p.read_text()
old = "Numeric pins double as regression tests. -/"
assert old in t
p.write_text(t.replace(old, "Numeric pins double as regression tests, and this is the strongest possible such bound. -/"))
PY
lake test >"$WORK/3c.log" 2>&1 || true   # advisory mode: exit stays 0
grep -q 'stale verdict for Renamed.hello_world' "$WORK/3c.log" || {
  echo "layer 3c FAIL: the claims gate did not report the stale verdict"; cat "$WORK/3c.log"; exit 1; }
echo "layer 3c PASS: stale verdict reported"

echo "selftest: all layers PASS"
