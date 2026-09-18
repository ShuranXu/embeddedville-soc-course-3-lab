import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class StarterContractTest(unittest.TestCase):
    def test_identity_is_course_scoped(self):
        manifest = json.loads((ROOT / "starter.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["courseId"], "interrupt-driven-soc-peripherals")
        self.assertEqual(manifest["starterVersion"], "course-3-v2.0.0")
        self.assertEqual(manifest["courseVersion"], "2026.10-soc-public-v2")
        self.assertEqual(manifest["evidenceSchema"], 4)
        self.assertEqual(manifest["repository"], "ShuranXu/embeddedville-soc-course-3-lab")
        self.assertEqual(manifest["ref"], "main")
        self.assertEqual(len(manifest["activities"]), 4)
        self.assertEqual(manifest["sourceFiles"], [
            "rtl/ahb_peripherals.sv", "firmware/startup/startup.S", "firmware/linker.ld",
            "firmware/include/soc.h", "firmware/src/drivers.c", "firmware/src/stopwatch.c",
            "starter.json", "design-note.md",
        ])

    def test_real_soc_structure_is_present(self):
        required = [
            "rtl/ahb_peripherals.sv", "firmware/startup/startup.S", "firmware/linker.ld",
            "firmware/include/soc.h", "firmware/src/drivers.c", "firmware/src/stopwatch.c",
            "sim/tb_ahb_peripherals.sv", "renode/soc.repl",
        ]
        self.assertTrue(all((ROOT / path).is_file() for path in required))

    def test_no_solution_or_sibling_course_assets(self):
        files = {path.relative_to(ROOT).as_posix().lower() for path in ROOT.rglob("*") if path.is_file() and ".git/" not in path.as_posix()}
        self.assertFalse(any("solution" in path or "course2" in path or "course4" in path for path in files))


if __name__ == "__main__":
    unittest.main()
