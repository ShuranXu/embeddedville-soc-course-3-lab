# Course 3 activities

This file is a command and contract index. The complete ordered procedures, expected observations, evidence checkpoints, recovery steps, and interpretation questions are in the protected EmbeddedVille lab manuals. The BFM supplies raw two-bit GPIO input; bit 0 is start/pause and bit 1 is reset. The project must remain deterministic when a timer event and a GPIO event are pending together.

## 1. Timer registers and acknowledgement

Implement the timer registers and countdown inside `rtl/ahb_peripherals.sv`. The AHB-Lite contract exposes CTRL, RELOAD, VALUE, and STATUS at `0x4000_0000`; STATUS bit 0 is sticky pending and a one write acknowledges it. Run:

```sh
./lab test --scenario timer-registers
```

Evidence: `results.json`, `ahb-trace.vcd`, `irq-trace.json`, tool identity, firmware identity, and the generated event trace.

## 2. GPIO events and five-digit display

Latch each rising GPIO edge exactly once in `rtl/ahb_peripherals.sv`, acknowledge it through the EVENT write-one-to-clear register, and implement the typed driver boundary. Complete `encode_mmss_t` in `firmware/src/stopwatch.c` so the display stores minute tens, minute ones, second tens, second ones, and tenths. Reset clears elapsed time without changing a paused stopwatch into a running one. Run:

```sh
./lab test --scenario gpio-sevenseg
```

Evidence: directed test result, display capture JSON, event trace, and waveform.

## 3. Interrupt integration and UART logging

Complete the GNU vector/handler path and keep the handlers short. Acknowledge the source, update only minimal shared state, and emit one UART event byte: `S` start, `P` pause, `R` reset, or `T` accepted tick. GPIO has higher priority than timer. A pause at the same event boundary as a tick prevents that tick from changing elapsed time. Run:

```sh
./lab test --scenario interrupt-integration
```

Evidence: `uart.log`, event-order trace, result JSON, and waveform from the same source digest.

## 4. Stopwatch project

Integrate the complete behavior and run all four required cases:

1. start/pause;
2. reset while paused;
3. simultaneous timer tick and GPIO event;
4. rollover from `99:59.9` to `00:00.0`.

```sh
./lab test --scenario stopwatch-project
./lab package --scenario stopwatch-project
```

The protected evaluator scores timer behavior (25), GPIO/display behavior (20), interrupt correctness/order (25), deterministic scenarios (15), and evidence/design explanation (15). The first four are critical gates. Passing requires at least 80/100 and every critical gate.

All packages use evidence schema 4, starter `course-3-v2.0.0`, and course version `2026.10-soc-public-v2`. Old v1 evidence remains historical and cannot satisfy this course version.
