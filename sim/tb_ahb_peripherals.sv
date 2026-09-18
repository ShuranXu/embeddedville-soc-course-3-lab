`timescale 1ns/1ps

module tb_ahb_peripherals;
  logic HCLK = 0, HRESETn = 0, HSEL = 0, HWRITE = 0, HREADY = 1;
  logic [31:0] HADDR = 0, HWDATA = 0, HRDATA;
  logic [1:0] HTRANS = 0, gpio_input = 0;
  logic [2:0] HSIZE = 3'b010;
  logic HREADYOUT, HRESP, timer_irq, gpio_irq, uart_tx_valid;
  logic [31:0] gpio_output, gpio_direction;
  logic [19:0] display_digits;
  logic [4:0] display_enable;
  logic [7:0] uart_tx_data;
  string scenario;
  integer failures = 0;
  integer uart_file, event_file, irq_file;

  always #5 HCLK = ~HCLK;
  ahb_peripherals #(.TIMER_CLOCK_HZ(100)) dut (.*);

  task automatic write_word(input logic [31:0] address, input logic [31:0] data);
    @(negedge HCLK); HSEL <= 1; HTRANS <= 2'b10; HWRITE <= 1; HADDR <= address;
    @(negedge HCLK); HSEL <= 0; HTRANS <= 0; HWDATA <= data;
    @(posedge HCLK); #1;
  endtask

  task automatic read_word(input logic [31:0] address, output logic [31:0] data);
    @(negedge HCLK); HSEL <= 1; HTRANS <= 2'b10; HWRITE <= 0; HADDR <= address;
    @(negedge HCLK); HSEL <= 0; HTRANS <= 0; #1; data = HRDATA;
    @(posedge HCLK); #1;
  endtask

  task automatic expect(input logic condition, input string label);
    if (condition) $display("PASS %s", label);
    else begin $display("FAIL %s", label); failures++; end
  endtask

  logic [31:0] value;
  initial begin
    if (!$value$plusargs("SCENARIO=%s", scenario)) scenario = "timer-registers";
    $dumpfile("ahb-trace.vcd"); $dumpvars(0, tb_ahb_peripherals);
    uart_file = $fopen("uart.log", "w"); event_file = $fopen("event-order.log", "w"); irq_file = $fopen("irq-trace.json", "w");
    repeat (3) @(posedge HCLK); HRESETn <= 1; repeat (2) @(posedge HCLK);
    if (scenario == "timer-registers") begin
      write_word(32'h40000004, 3); write_word(32'h40000000, 7); repeat (5) @(posedge HCLK);
      read_word(32'h4000000C, value); expect(value[0] && timer_irq, "terminal count sets pending and IRQ");
      write_word(32'h4000000C, 0); read_word(32'h4000000C, value); expect(value[0], "zero write does not clear pending");
      write_word(32'h4000000C, 1); expect(!timer_irq, "W1C acknowledgement clears IRQ");
    end else if (scenario == "gpio-sevenseg") begin
      write_word(32'h4001000C, 3); gpio_input <= 1; @(posedge HCLK); gpio_input <= 0; repeat (2) @(posedge HCLK);
      read_word(32'h40010008, value); expect(value[0] && gpio_irq, "GPIO edge latches event");
      write_word(32'h40020000, 20'h01015); write_word(32'h40020004, 5'h1F);
      expect(display_digits == 20'h01015 && display_enable == 5'h1F, "five-digit MMSS.t storage");
    end else if (scenario == "interrupt-integration") begin
      expect(1'b0, "complete firmware and Renode interrupt integration before this scenario can pass");
    end else if (scenario == "stopwatch-project") begin
      expect(1'b0, "complete all four deterministic firmware scenarios before the project can pass");
    end else expect(1'b0, "known scenario");
    $fwrite(irq_file, "{\"timerIrq\":%0d,\"gpioIrq\":%0d}\n", timer_irq, gpio_irq);
    $fwrite(event_file, "scenario=%s failures=%0d\n", scenario, failures);
    $fwrite(uart_file, "%c", uart_tx_valid ? uart_tx_data : 8'h2D);
    $fclose(irq_file); $fclose(event_file); $fclose(uart_file);
    if (failures == 0) $display("RESULT PASS scenario=%s", scenario);
    else begin $display("RESULT FAIL scenario=%s failures=%0d", scenario, failures); $fatal(1); end
    $finish;
  end
endmodule
