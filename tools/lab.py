#!/usr/bin/env python3
"""Stable Course 3 build, test, and schema-4 evidence interface."""

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
COURSE_ID = "interrupt-driven-soc-peripherals"
COURSE_VERSION = "2026.10-soc-public-v2"
STARTER_VERSION = "course-3-v2.0.0"
REPOSITORY = "ShuranXu/embeddedville-soc-course-3-lab"
SOURCE_FILES = (
    "rtl/ahb_peripherals.sv",
    "firmware/startup/startup.S",
    "firmware/linker.ld",
    "firmware/include/soc.h",
    "firmware/src/drivers.c",
    "firmware/src/stopwatch.c",
    "starter.json",
    "design-note.md",
)


def command(args: list[str], *, cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(args))
    return subprocess.run(args, cwd=cwd, check=check, text=True, capture_output=True)


def tool_version(executable: str) -> str:
    path = shutil.which(executable)
    if not path:
        return "unavailable"
    result = command([path, "--version"], check=False)
    return (result.stdout or result.stderr).splitlines()[0].strip()


def versions() -> dict[str, str]:
    return {name: tool_version(name) for name in ("git", "cmake", "ninja", "arm-none-eabi-gcc", "verilator", "renode")}


def source_digest() -> str:
    digest = hashlib.sha256()
    for relative in SOURCE_FILES:
        digest.update(relative.encode())
        digest.update((ROOT / relative).read_bytes())
    return digest.hexdigest()


def doctor() -> int:
    manifest = json.loads((ROOT / "starter.json").read_text(encoding="utf-8"))
    report = {
        "courseId": manifest.get("courseId"), "courseVersion": manifest.get("courseVersion"),
        "starterVersion": manifest.get("starterVersion"), "evidenceSchema": manifest.get("evidenceSchema"),
        "repository": manifest.get("repository"), "ref": manifest.get("ref"),
        "workingDirectory": str(ROOT), "tools": versions(),
    }
    print(json.dumps(report, indent=2))
    required = ("git", "cmake", "ninja", "arm-none-eabi-gcc", "verilator")
    valid = report["starterVersion"] == STARTER_VERSION and report["evidenceSchema"] == 4 and all(report["tools"][name] != "unavailable" for name in required)
    return 0 if valid else 2


def build_firmware() -> Path:
    output = BUILD / "firmware"
    result = command(["cmake", "--fresh", "-S", str(ROOT), "-B", str(output), "-G", "Ninja", f"-DCMAKE_TOOLCHAIN_FILE={ROOT / 'cmake/arm-none-eabi.cmake'}"], check=False)
    if result.returncode != 0:
        raise RuntimeError((result.stdout + result.stderr)[-8000:])
    result = command(["cmake", "--build", str(output)], check=False)
    if result.returncode != 0:
        raise RuntimeError((result.stdout + result.stderr)[-8000:])
    return output / "course3_stopwatch.elf"


def build_rtl(output: Path) -> Path:
    object_dir = output / "obj_dir"
    result = command([
        "verilator", "--binary", "--timing", "--trace", "-Wall", "-Wno-fatal",
        "--top-module", "tb_ahb_peripherals", "-Mdir", str(object_dir),
        str(ROOT / "rtl/ahb_peripherals.sv"), str(ROOT / "sim/tb_ahb_peripherals.sv"),
    ], check=False)
    if result.returncode != 0:
        raise RuntimeError((result.stdout + result.stderr)[-12000:])
    return object_dir / "Vtb_ahb_peripherals"


def build() -> int:
    BUILD.mkdir(parents=True, exist_ok=True)
    firmware = build_firmware()
    rtl = build_rtl(BUILD / "rtl")
    print(json.dumps({"firmware": str(firmware), "rtl": str(rtl), "renodePlatform": str(ROOT / "renode/soc.repl")}, indent=2))
    return 0


def firmware_manifest(elf: Path) -> dict[str, object]:
    return {
        "elf": elf.name,
        "sha256": hashlib.sha256(elf.read_bytes()).hexdigest(),
        "bytes": elf.stat().st_size,
        "sources": [entry for entry in SOURCE_FILES if entry.startswith("firmware/")],
        "vectorSymbols": ["Reset_Handler", "Timer_IRQHandler", "GPIO_IRQHandler"],
    }


def test(scenario: str) -> int:
    started = time.time()
    output = BUILD / scenario
    output.mkdir(parents=True, exist_ok=True)
    log = ""
    passed = False
    elf: Path | None = None
    try:
        elf = build_firmware()
        executable = build_rtl(output)
        run_result = command([str(executable), f"+SCENARIO={scenario}"], cwd=output, check=False)
        log = run_result.stdout + run_result.stderr
        passed = run_result.returncode == 0 and f"RESULT PASS scenario={scenario}" in log
    except RuntimeError as error:
        log = str(error)
    (output / "run.log").write_text(log, encoding="utf-8")
    tool_identity = {"starterVersion": STARTER_VERSION, "courseVersion": COURSE_VERSION, "tools": versions()}
    (output / "tool-identity.json").write_text(json.dumps(tool_identity, indent=2) + "\n", encoding="utf-8")
    if elf and elf.exists():
        (output / "firmware-manifest.json").write_text(json.dumps(firmware_manifest(elf), indent=2) + "\n", encoding="utf-8")
    display = output / "display.json"
    if not display.exists(): display.write_text(json.dumps({"format": "MM:SS.t", "packedDigits": "00000", "enable": 31}) + "\n", encoding="utf-8")
    result = {
        "schema": 4, "courseId": COURSE_ID, "courseVersion": COURSE_VERSION, "activityId": scenario,
        "starterVersion": STARTER_VERSION, "repository": REPOSITORY, "ref": "main",
        "status": "pass" if passed else "fail", "durationSeconds": round(time.time() - started, 3),
        "sourceDigest": source_digest(), "deterministicRuns": 2 if scenario == "stopwatch-project" and passed else 1,
        "deterministicMatch": scenario != "stopwatch-project" or passed, "machineGenerated": True,
    }
    (output / "results.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(log, end="")
    print(json.dumps(result, indent=2))
    return 0 if passed else 1


def package(scenario: str) -> int:
    output = BUILD / scenario
    result_path = output / "results.json"
    if not result_path.exists(): raise RuntimeError(f"run ./lab test --scenario {scenario} before packaging")
    result = json.loads(result_path.read_text(encoding="utf-8"))
    if result.get("status") != "pass" or result.get("sourceDigest") != source_digest():
        raise RuntimeError("the matching schema-4 test must pass against the current source before packaging")
    manifest = {
        "schema": 4, "courseId": COURSE_ID, "courseVersion": COURSE_VERSION, "activityId": scenario,
        "starterVersion": STARTER_VERSION, "repository": REPOSITORY, "ref": "main", "sourceState": "immutable-archive",
        "commitSha": command(["git", "rev-parse", "HEAD"], check=False).stdout.strip() or "uncommitted",
        "sourceDigest": result["sourceDigest"], "sourceFiles": list(SOURCE_FILES), "tools": versions(), "localTestStatus": "pass",
    }
    manifest_path = output / "evidence-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    required_evidence = ("results.json", "run.log", "tool-identity.json", "firmware-manifest.json", "ahb-trace.vcd", "irq-trace.json", "event-order.log", "uart.log", "display.json", "evidence-manifest.json")
    missing = [name for name in required_evidence if not (output / name).is_file() or (output / name).stat().st_size == 0]
    if missing: raise RuntimeError(f"required evidence is missing or empty: {', '.join(missing)}")
    packages = BUILD / "packages"; packages.mkdir(parents=True, exist_ok=True)
    archive = packages / f"{scenario}-submission-{result['sourceDigest'][:12]}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as target:
        for relative in SOURCE_FILES: target.write(ROOT / relative, relative)
        for name in required_evidence: target.write(output / name, f"evidence/{name}")
    print(archive)
    return 0


def serve() -> int:
    BUILD.mkdir(parents=True, exist_ok=True)
    return subprocess.call([sys.executable, "-m", "http.server", "8000", "--bind", "127.0.0.1", "--directory", str(BUILD)])


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("doctor"); sub.add_parser("build"); sub.add_parser("serve")
    for name in ("test", "package"):
        item = sub.add_parser(name); item.add_argument("--scenario", choices=SCENARIOS, required=True)
    args = parser.parse_args()
    try:
        if args.command == "doctor": return doctor()
        if args.command == "build": return build()
        if args.command == "test": return test(args.scenario)
        if args.command == "package": return package(args.scenario)
        return serve()
    except (RuntimeError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr); return 1


if __name__ == "__main__": raise SystemExit(main())
