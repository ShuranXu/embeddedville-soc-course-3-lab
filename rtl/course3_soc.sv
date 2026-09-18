`timescale 1ns/1ps

// Course 3 starter. Implement the TODOs described in docs/activities.md.
// The interface intentionally exposes acknowledgement and event evidence so
// local and protected tests can verify interrupt behavior without a solution.
module course3_soc #(
    parameter int TICK_CYCLES = 10,
    parameter int MAX_TENTHS = 60000
) (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [1:0]  button_event,
    output logic        timer_irq,
    output logic        button_irq,
    output logic        timer_ack_pulse,
    output logic        button_ack_pulse,
    output logic        running,
    output logic [15:0] elapsed_tenths,
    output logic [19:0] display_digits,
    output logic [4:0]  display_enable,
    output logic        uart_valid,
    output logic [7:0]  uart_data
);
    // TODO(timer-registers): implement enable, periodic reload, pending state,
    // interrupt enable, and acknowledgement semantics. Pending must be held
    // until an acknowledgement is issued.

    // TODO(gpio-sevenseg): capture each debounced button event exactly once,
    // acknowledge it, and convert elapsed tenths to five BCD display nibbles
    // in MMSS.t order.

    // TODO(interrupt-integration): service button events before timer events,
    // keep handlers short, update shared state deterministically, and emit
    // S/P/R/T event bytes on uart_data with a one-cycle uart_valid pulse.

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            timer_irq <= 1'b0;
            button_irq <= 1'b0;
            timer_ack_pulse <= 1'b0;
            button_ack_pulse <= 1'b0;
            running <= 1'b0;
            elapsed_tenths <= 16'd0;
            uart_valid <= 1'b0;
            uart_data <= 8'd0;
        end else begin
            timer_irq <= timer_irq;
            button_irq <= |button_event;
            timer_ack_pulse <= 1'b0;
            button_ack_pulse <= 1'b0;
            running <= running;
            elapsed_tenths <= elapsed_tenths;
            uart_valid <= 1'b0;
            uart_data <= uart_data;
        end
    end

    always_comb begin
        display_digits = 20'h00000;
        display_enable = 5'b11111;
    end

    logic _unused;
    always_comb _unused = button_event[0] ^ TICK_CYCLES[0] ^ MAX_TENTHS[0];
endmodule

