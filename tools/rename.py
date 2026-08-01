#!/usr/bin/env python3
"""Rename the template project in place: directories, modules, imports,
lakefile, Makefile, CI, scripts, and the statement lock.

Usage: rename.py NewName [--root DIR]

NewName must match [A-Z][A-Za-z0-9]*. The rewrite is word-boundary-safe:
identifiers that merely *contain* the old name (Lean API names such as
`realizeGlobalConstNoOverload`, or prose uses of the English word
"template") are never touched. Compound identifiers are renamed by
explicit rule, longest first, so the bare-name pass cannot split them.
"""
import argparse
import re
import sys
from pathlib import Path

OLD = "Template"
SKIP_DIRS = {".git", ".lake", ".verify", "__pycache__"}
TEXT_SUFFIXES = {".lean", ".py", ".sh", ".toml", ".md", ".yml", ".yaml", ".lock", ".json", ""}


def lower_first(s: str) -> str:
    return s[0].lower() + s[1:]


def rules(new: str):
    old_l, new_l = lower_first(OLD), lower_first(new)
    # Longest-first, word-bounded. The lowercase English word "template"
    # is deliberately not a rule: prose keeps it.
    return [
        (re.compile(rf"\b{OLD}Test\b"), f"{new}Test"),
        (re.compile(rf"\b{old_l}Test\b"), f"{new_l}Test"),
        (re.compile(rf"\b{old_l}OmittedTokens\b"), f"{new_l}OmittedTokens"),
        (re.compile(rf"\b{OLD}\b"), new),
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("new_name")
    ap.add_argument("--root", default=".")
    args = ap.parse_args()
    new = args.new_name
    if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", new) or new == OLD:
        sys.exit(f"rename.py: NewName must match [A-Z][A-Za-z0-9]* and differ from {OLD}")
    root = Path(args.root).resolve()
    rs = rules(new)
    changed = 0
    for p in sorted(root.rglob("*")):
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if not p.is_file() or p.suffix not in TEXT_SUFFIXES or p.name == "LICENSE":
            continue
        try:
            t = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        t2 = t
        for rx, rep in rs:
            t2 = rx.sub(rep, t2)
        if t2 != t:
            p.write_text(t2, encoding="utf-8")
            changed += 1
    # Directory and file renames, deepest paths first.
    moves = [(root / f"{OLD}.lean", root / f"{new}.lean"),
             (root / f"{OLD}Test", root / f"{new}Test"),
             (root / OLD, root / new)]
    for src, dst in moves:
        if src.exists():
            if dst.exists():
                sys.exit(f"rename.py: refusing to overwrite {dst}")
            src.rename(dst)
    print(f"rename.py: {OLD} -> {new}: {changed} file(s) rewritten, "
          f"{sum(1 for s, _ in moves if not s.exists())} path(s) moved")
    print(f"next: lake build && lake test  (the gates re-verify the rename)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
