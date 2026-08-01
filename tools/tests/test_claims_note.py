"""claims.py must refuse a note that would corrupt its own pipe-delimited
ledger: a `|` in --note once wrote a row every later invocation rejected."""
import subprocess
import sys
import unittest
from pathlib import Path

CLAIMS = Path(__file__).resolve().parents[2] / "scripts" / "claims.py"


class NoteEscaping(unittest.TestCase):
    def test_pipe_in_note_rejected(self):
        r = subprocess.run(
            [sys.executable, str(CLAIMS), "record", "X.y", "accepted",
             "--note", "left|right"],
            capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("may not contain", r.stderr + r.stdout)

    def test_newline_in_note_rejected(self):
        r = subprocess.run(
            [sys.executable, str(CLAIMS), "record", "X.y", "accepted",
             "--note", "a\nb"],
            capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)


if __name__ == "__main__":
    unittest.main()
