"""rename.py must rename whole words only: the blind-substring failure it
exists to prevent (a Lean API name mangled by a substring rename) is
constructed here and must survive."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOL = Path(__file__).resolve().parents[1] / "rename.py"


def run(root):
    return subprocess.run([sys.executable, str(TOOL), "Audit", "--root", str(root)],
                          capture_output=True, text=True)


class Rename(unittest.TestCase):
    def build(self, root):
        (root / "Template").mkdir()
        (root / "TemplateTest").mkdir()
        (root / "Template.lean").write_text(
            "public import Template.Basic\n", encoding="utf-8")
        (root / "Template" / "A.lean").write_text(
            "-- realizeGlobalConstNoOverload and fooTemplateBar stay\n"
            "namespace Template\ndef templateOmittedTokens : List String := []\n"
            "#eval templateTest\nend Template\n", encoding="utf-8")
        (root / "TemplateTest" / "B.lean").write_text(
            "import TemplateTest.Gate\n", encoding="utf-8")
        (root / "README.md").write_text(
            "A template for Template libraries; the template word stays.\n",
            encoding="utf-8")

    def test_word_boundary_rename(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self.build(root)
            r = run(root)
            self.assertEqual(r.returncode, 0, r.stderr)
            a = (root / "Audit" / "A.lean").read_text(encoding="utf-8")
            self.assertIn("fooTemplateBar stay", a)          # embedded name untouched
            self.assertIn("realizeGlobalConstNoOverload", a) # API-name shape untouched
            self.assertIn("namespace Audit", a)
            self.assertIn("auditOmittedTokens", a)
            self.assertIn("#eval auditTest", a)
            self.assertIn("import AuditTest.Gate",
                          (root / "AuditTest" / "B.lean").read_text(encoding="utf-8"))
            self.assertIn("public import Audit.Basic",
                          (root / "Audit.lean").read_text(encoding="utf-8"))
            readme = (root / "README.md").read_text(encoding="utf-8")
            self.assertIn("A template for Audit libraries", readme)
            self.assertIn("the template word stays", readme)

    def test_rejects_bad_name(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); self.build(root)
            r = subprocess.run([sys.executable, str(TOOL), "bad-name", "--root", str(root)],
                               capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)


if __name__ == "__main__":
    unittest.main()
