# Course 3 activities

The scenario driver supplies already-debounced, one-cycle button events. Button bit 0 is start/pause and bit 1 is reset. The project must remain deterministic when a timer event and a button event arrive together.

## 1. Timer registers and acknowledgement

Implement a periodic timer inside `rtl/course3_soc.sv`. While the stopwatch is running, the timer counts `TICK_CYCLES`, asserts a pending interrupt, holds it until the controller acknowledges it, and reloads for the next period. `timer_irq` exposes pending-and-enabled state; `timer_ack_pulse` proves write-one-to-clear-style acknowledgement. Run:

```sh
./lab test --scenario timer-registers
```

Evidence: `results.json`, the timer section of `trace.vcd`, and the generated event trace.

## 2. GPIO events and five-digit display

Capture each button pulse exactly once, acknowledge it with `button_ack_pulse`, and drive five BCD nibbles in `display_digits`: minute tens, minute ones, second tens, second ones, and tenths. `display_enable` is `5'b11111`; the course display places a fixed decimal point before tenths. Reset clears elapsed time without changing a paused stopwatch into a running one. Run:

```sh
./lab test --scenario gpio-sevenseg
```

Evidence: directed test result, display capture JSON, event trace, and waveform.

## 3. Interrupt integration and UART logging

Use short event handlers. Acknowledge the source, update only the minimal shared state, and emit one UART event byte: `S` start, `P` pause, `R` reset, or `T` accepted tick. If button and timer events are pending together, service the button first. A pause at the same instant as a tick prevents that tick from changing elapsed time. Run:

```sh
./lab test --scenario interrupt-integration
```

Evidence: `uart.log`, event-order trace, result JSON, and waveform from the same source digest.

## 4. Stopwatch project

Integrate the complete behavior and run all four required cases:

1. start/pause;
2. reset while paused;
3. simultaneous timer tick and button event;
4. rollover from `99:59.9` to `00:00.0`.

```sh
./lab test --scenario stopwatch-project
./lab package --scenario stopwatch-project
```

The protected evaluator scores timer behavior (25), GPIO/display behavior (20), interrupt correctness/order (25), deterministic scenarios (15), and evidence/design explanation (15). The first four are critical gates. Passing requires at least 80/100 and every critical gate.

