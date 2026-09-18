import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class StarterContractTest(unittest.TestCase):
    def test_identity_is_course_scoped(self):
        manifest = json.loads((ROOT / "starter.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["courseId"], "interrupt-driven-soc-peripherals")
        self.assertEqual(manifest["starterVersion"], "course-3-v1.0.0")
        self.assertEqual(manifest["repository"], "ShuranXu/embeddedville-soc-course-3-lab")
        self.assertEqual(manifest["ref"], "main")
        self.assertEqual(len(manifest["activities"]), 4)

    def test_no_solution_or_sibling_course_assets(self):
        files = {path.relative_to(ROOT).as_posix().lower() for path in ROOT.rglob("*") if path.is_file() and ".git/" not in path.as_posix()}
        self.assertFalse(any("solution" in path or "course2" in path or "course4" in path for path in files))


if __name__ == "__main__":
    unittest.main()

