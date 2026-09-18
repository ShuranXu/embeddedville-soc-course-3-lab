#!/usr/bin/env python3
"""Stable local test and evidence interface for SoC Course 3."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
SCENARIOS = ("timer-registers", "gpio-sevenseg", "interrupt-integration", "stopwatch-project")
STARTER_VERSION = "course-3-v1.0.0"
SOURCE_FILES = ("rtl/course3_soc.sv", "starter.json", "design-note.md")


def command(args: list[str], *, cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(args))
    return subprocess.run(args, cwd=cwd, check=check, text=True, capture_output=True)


def version(executable: str) -> str:
    path = shutil.which(executable)
    if not path:
        return "unavailable"
    result = command([path, "--version"], check=False)
    return (result.stdout or result.stderr).splitlines()[0].strip()


def versions() -> dict[str, str]:
    return {"python": sys.version.split()[0], "verilator": version("verilator"), "git": version("git")}


def doctor() -> int:
    manifest = json.loads((ROOT / "starter.json").read_text(encoding="utf-8"))
    report = {**versions(), "courseId": manifest.get("courseId"), "starterVersion": manifest.get("starterVersion"), "workingDirectory": str(ROOT)}
    print(json.dumps(report, indent=2))
    return 0 if report["verilator"] != "unavailable" and report["git"] != "unavailable" and report["starterVersion"] == STARTER_VERSION else 2


def source_digest() -> str:
    digest = hashlib.sha256()
    for relative in SOURCE_FILES:
        digest.update(relative.encode())
        digest.update((ROOT / relative).read_bytes())
    return digest.hexdigest()


def test(scenario: str) -> int:
    started = time.time()
    output = BUILD / scenario
    object_dir = output / "obj_dir"
    output.mkdir(parents=True, exist_ok=True)
    compile_result = command([
        "verilator", "--binary", "--timing", "--trace", "-Wall", "-Wno-fatal",
        "--top-module", "tb_course3", "-Mdir", str(object_dir),
        str(ROOT / "rtl/course3_soc.sv"), str(ROOT / "sim/tb_course3.sv"),
    ], check=False)
    log = compile_result.stdout + compile_result.stderr
    passed = compile_result.returncode == 0
    if passed:
        run_result = command([str(object_dir / "Vtb_course3"), f"+SCENARIO={scenario}"], cwd=output, check=False)
        log += run_result.stdout + run_result.stderr
        passed = run_result.returncode == 0 and f"RESULT PASS scenario={scenario}" in log
    (output / "run.log").write_text(log, encoding="utf-8")
    result = {
        "schema": 1,
        "courseId": "interrupt-driven-soc-peripherals",
        "activityId": scenario,
        "starterVersion": STARTER_VERSION,
        "repository": "ShuranXu/embeddedville-soc-course-3-lab",
        "ref": "main",
        "status": "pass" if passed else "fail",
        "durationSeconds": round(time.time() - started, 3),
        "sourceDigest": source_digest(),
        "toolVersions": versions(),
        "artifacts": sorted(path.name for path in output.iterdir() if path.is_file()),
        "machineGenerated": True,
    }
    (output / "results.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(log, end="")
    print(json.dumps(result, indent=2))
    return 0 if passed else 1


def package(scenario: str) -> int:
    output = BUILD / scenario
    result_path = output / "results.json"
    if not result_path.exists():
        raise RuntimeError(f"run ./lab test --scenario {scenario} before packaging")
    result = json.loads(result_path.read_text(encoding="utf-8"))
    if result.get("status") != "pass" or result.get("sourceDigest") != source_digest():
        raise RuntimeError("the matching test must pass against the current source before packaging")
    manifest = {
        "schema": 3,
        "courseId": "interrupt-driven-soc-peripherals",
        "activityId": scenario,
        "starterVersion": STARTER_VERSION,
        "repository": "ShuranXu/embeddedville-soc-course-3-lab",
        "ref": "main",
        "sourceState": "immutable-archive",
        "commitSha": command(["git", "rev-parse", "HEAD"], check=False).stdout.strip() or "uncommitted",
        "sourceDigest": result["sourceDigest"],
        "sourceFiles": list(SOURCE_FILES),
        "toolVersions": result["toolVersions"],
        "localTestStatus": result["status"],
    }
    manifest_path = output / "evidence-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    packages = BUILD / "packages"
    packages.mkdir(parents=True, exist_ok=True)
    archive = packages / f"{scenario}-submission-{result['sourceDigest'][:12]}.zip"
    allowed = [ROOT / path for path in SOURCE_FILES] + [result_path, manifest_path, output / "run.log", output / "trace.vcd", output / "uart.log", output / "event-order.log", output / "display.json"]
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as target:
        for path in allowed:
            if path.exists():
                name = path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) and path.parent != output else f"evidence/{path.name}"
                target.write(path, name)
    print(archive)
    return 0


def serve() -> int:
    BUILD.mkdir(parents=True, exist_ok=True)
    return subprocess.call([sys.executable, "-m", "http.server", "8000", "--bind", "127.0.0.1", "--directory", str(BUILD)])


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("doctor")
    for name in ("test", "package"):
        item = sub.add_parser(name)
        item.add_argument("--scenario", choices=SCENARIOS, required=True)
    sub.add_parser("serve")
    args = parser.parse_args()
    try:
        if args.command == "doctor": return doctor()
        if args.command == "test": return test(args.scenario)
        if args.command == "package": return package(args.scenario)
        return serve()
    except (RuntimeError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
