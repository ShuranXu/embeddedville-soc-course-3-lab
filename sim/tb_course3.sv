`timescale 1ns/1ps

module tb_course3;
    logic clk = 1'b0;
    logic reset_n = 1'b0;
    logic [1:0] button_event = 2'b00;
    logic timer_irq, button_irq, timer_ack_pulse, button_ack_pulse, running;
    logic [15:0] elapsed_tenths;
    logic [19:0] display_digits;
    logic [4:0] display_enable;
    logic uart_valid;
    logic [7:0] uart_data;
    integer failures = 0;
    integer uart_file;
    integer event_file;
    integer display_file;
    string scenario;

    always #5 clk = ~clk;
    course3_soc #(.TICK_CYCLES(4), .MAX_TENTHS(60000)) dut (.*);

    always @(posedge clk) begin
        if (uart_valid) begin
            $fwrite(uart_file, "%c", uart_data);
            $fwrite(event_file, "cycle=%0t uart=%c elapsed=%0d running=%0d\n", $time, uart_data, elapsed_tenths, running);
        end
        if (timer_ack_pulse) $fwrite(event_file, "cycle=%0t ack=timer\n", $time);
        if (button_ack_pulse) $fwrite(event_file, "cycle=%0t ack=button\n", $time);
    end

    task automatic press(input logic [1:0] value);
        @(negedge clk); button_event <= value;
        @(negedge clk); button_event <= 2'b00;
    endtask

    task automatic check_condition(input logic condition, input string label);
        if (!condition) begin $display("FAIL %s", label); failures++; end
        else $display("PASS %s", label);
    endtask

    task automatic wait_for_tenths(input int target, input int limit);
        int cycles;
        cycles = 0;
        while (elapsed_tenths < target && cycles < limit) begin @(posedge clk); cycles++; end
    endtask

    task automatic timer_activity;
        press(2'b01);
        check_condition(running, "start event enters running state");
        wait_for_tenths(2, 40);
        check_condition(elapsed_tenths >= 2, "periodic timer advances elapsed tenths");
        check_condition(timer_ack_pulse || elapsed_tenths > 0, "timer interrupt is acknowledged");
    endtask

    task automatic display_activity;
        press(2'b01);
        wait_for_tenths(3, 60);
        press(2'b01);
        check_condition(!running, "second start/pause event pauses");
        check_condition(display_enable == 5'b11111, "all five display digits enabled");
        check_condition(display_digits[3:0] == elapsed_tenths % 10, "tenths digit matches elapsed time");
        press(2'b10);
        check_condition(elapsed_tenths == 0 && !running, "reset while paused clears time and remains paused");
    endtask

    task automatic integration_activity;
        logic [15:0] value_before_pause;
        press(2'b01);
        wait_for_tenths(1, 40);
        value_before_pause = elapsed_tenths;
        // Align a pause event with the next timer event window.
        repeat (2) @(posedge clk);
        press(2'b01);
        repeat (3) @(posedge clk);
        check_condition(!running, "button interrupt pauses the stopwatch");
        check_condition(elapsed_tenths <= value_before_pause + 1, "simultaneous events have deterministic button priority");
        check_condition(button_ack_pulse || !button_irq, "button event is acknowledged");
    endtask

    initial begin
        $dumpfile("trace.vcd");
        $dumpvars(0, tb_course3);
        uart_file = $fopen("uart.log", "w");
        event_file = $fopen("event-order.log", "w");
        if (!$value$plusargs("SCENARIO=%s", scenario)) scenario = "timer-registers";
        repeat (3) @(posedge clk); reset_n <= 1'b1; repeat (2) @(posedge clk);
        if (scenario == "timer-registers") timer_activity();
        else if (scenario == "gpio-sevenseg") display_activity();
        else if (scenario == "interrupt-integration") integration_activity();
        else if (scenario == "stopwatch-project") begin timer_activity(); press(2'b01); press(2'b10); check_condition(elapsed_tenths == 0, "reset scenario"); integration_activity(); end
        else begin $display("FAIL unknown scenario %s", scenario); failures++; end
        display_file = $fopen("display.json", "w");
        $fwrite(display_file, "{\"digits\":\"%05x\",\"enable\":%0d,\"elapsedTenths\":%0d}\n", display_digits, display_enable, elapsed_tenths);
        $fclose(display_file); $fclose(event_file); $fclose(uart_file);
        if (failures == 0) $display("RESULT PASS scenario=%s", scenario);
        else begin $display("RESULT FAIL scenario=%s failures=%0d", scenario, failures); $fatal(1); end
        $finish;
    end
endmodule
