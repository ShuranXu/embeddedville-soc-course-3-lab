# EmbeddedVille SoC Course 3 workspace

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ShuranXu/embeddedville-soc-course-3-lab/tree/main?quickstart=1)

This is the solution-free starter for the paid **Interrupt-Driven SoC Peripherals** course. It contains a real AHB-Lite peripheral bank, GNU Cortex-M0 startup and linker files, typed register definitions, drivers, an intentionally incomplete stopwatch application, open tests, and private evidence-packaging tools. Complete manuals, submissions, and certificate progress stay in the protected EmbeddedVille course workspace.

## First action

Open the matching EmbeddedVille manual, inspect [docs/activities.md](docs/activities.md), and work only in the files named by that phase. Begin with:

```sh
./lab test --scenario timer-registers
./lab test --scenario gpio-sevenseg
./lab test --scenario interrupt-integration
./lab test --scenario stopwatch-project
```

The starter is intentionally incomplete, so each first scenario should fail meaningfully. `./lab build` compiles the GNU Cortex-M0 firmware and the Verilator bus-functional model. Passing local runs create schema-4 results, AHB and IRQ traces, tool and firmware manifests, UART/event logs, and display state from the current source. Package that exact state with:

```sh
./lab package --scenario timer-registers
```

Upload the ZIP at the end of the matching paid-course lab or project manual. EmbeddedVille verifies the Course 3 v2 identity and source digest, rebuilds submitted RTL and firmware, and runs separate protected scenarios. Editing a local result cannot approve an activity. The project passes only at 80/100 or higher with every critical gate passing.

## Workspace identity

- Course: `interrupt-driven-soc-peripherals`
- Repository/ref: `ShuranXu/embeddedville-soc-course-3-lab@main`
- Starter: `course-3-v2.0.0`
- Course version: `2026.10-soc-public-v2`
- Evidence schema: `4`
- Dev container: `.devcontainer/devcontainer.json`
- Working directory: repository root
- Learner source: `rtl/ahb_peripherals.sv`, `firmware/startup/startup.S`, `firmware/include/soc.h`, `firmware/src/drivers.c`, and `firmware/src/stopwatch.c`
- Readiness check: `./lab doctor`

If `starter.json` or `git status` shows a different identity, preserve your edits in a private commit or exported patch before pulling, rebuilding, or creating a new Codespace.

## Codespaces lifecycle, cost, and recovery

You need a GitHub account, a supported browser, internet access, and available Codespaces quota. The account that creates the Codespace supplies the quota and is normally the billing owner; Codespaces is not universally free. The requested machine is 2 CPU / 4 GB RAM / 16 GB storage.

Closing the browser tab does not immediately stop compute. Stop the Codespace when finished. A stopped Codespace keeps saved files but may still incur storage cost. Editor save is not a commit, a commit is not a push, and neither action submits course evidence. Deleting a Codespace or reaching its retention expiry can remove unpushed work. Before deletion, replacement, full rebuild, or forced synchronization, commit and push to a **private** repository or export a patch/ZIP.

A normal rebuild preserves files under `/workspaces` and clears changes outside it. A stopped session can resume with older starter or container state; run `./lab doctor` and inspect `starter.json` after resuming. If initialization fails, open the creation log and retry the post-create command. If the wrong branch opens, preserve changes and create a new session from the branch-specific link above. If quota, policy, region, permissions, or network access blocks Codespaces, use the same dev container locally as the supported alternative.

The workspace requests no access to sibling repositories and uses no course secrets. Port 8000 is private and optional; `./lab serve` exposes only local evidence to your authenticated Codespaces session. Stop the server when finished.

Use is governed by [LICENSE-COURSE-USE.md](LICENSE-COURSE-USE.md).
