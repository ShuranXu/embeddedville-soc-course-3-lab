`timescale 1ns/1ps

// Solution-free Course 3 AHB-Lite peripheral bank. Address/control are
// captured in the address phase; HWDATA is consumed in the matching data phase.
module ahb_peripherals #(
  parameter int TIMER_CLOCK_HZ = 1_000_000
) (
  input  logic        HCLK,
  input  logic        HRESETn,
  input  logic        HSEL,
  input  logic [31:0] HADDR,
  input  logic [1:0]  HTRANS,
  input  logic        HWRITE,
  input  logic [2:0]  HSIZE,
  input  logic [31:0] HWDATA,
  input  logic        HREADY,
  output logic [31:0] HRDATA,
  output logic        HREADYOUT,
  output logic        HRESP,
  input  logic [1:0]  gpio_input,
  output logic [31:0] gpio_output,
  output logic [31:0] gpio_direction,
  output logic [19:0] display_digits,
  output logic [4:0]  display_enable,
  output logic        timer_irq,
  output logic        gpio_irq,
  output logic        uart_tx_valid,
  output logic [7:0]  uart_tx_data
);
  localparam logic [15:0] TIMER_PAGE  = 16'h4000;
  localparam logic [15:0] GPIO_PAGE   = 16'h4001;
  localparam logic [15:0] DISPLAY_PAGE= 16'h4002;
  localparam logic [15:0] UART_PAGE   = 16'h4003;

  logic transfer_pending;
  logic [31:0] transfer_address;
  logic transfer_write;
  logic [2:0] transfer_size;

  logic [31:0] timer_control;
  logic [31:0] timer_reload;
  logic [31:0] timer_value;
  logic timer_pending;
  logic [1:0] gpio_previous;
  logic [1:0] gpio_event;
  logic [1:0] gpio_irq_enable;

  wire address_phase = HSEL && HTRANS[1] && HREADY;
  wire word_access = transfer_size == 3'b010 && transfer_address[1:0] == 2'b00;
  wire known_page = transfer_address[31:16] inside {TIMER_PAGE, GPIO_PAGE, DISPLAY_PAGE, UART_PAGE};

  assign HREADYOUT = 1'b1;
  assign HRESP = transfer_pending && (!word_access || !known_page);
  assign timer_irq = timer_pending && timer_control[2];
  assign gpio_irq = |(gpio_event & gpio_irq_enable);

  always_comb begin
    HRDATA = 32'd0;
    if (transfer_pending && word_access) begin
      unique case (transfer_address[31:16])
        TIMER_PAGE: unique case (transfer_address[5:2])
          4'd0: HRDATA = timer_control;
          4'd1: HRDATA = timer_reload;
          4'd2: HRDATA = timer_value;
          4'd3: HRDATA = {31'd0, timer_pending};
          default: HRDATA = 32'd0;
        endcase
        GPIO_PAGE: unique case (transfer_address[5:2])
          4'd0: HRDATA = gpio_output;
          4'd1: HRDATA = gpio_direction;
          4'd2: HRDATA = {30'd0, gpio_event};
          4'd3: HRDATA = {30'd0, gpio_irq_enable};
          default: HRDATA = 32'd0;
        endcase
        DISPLAY_PAGE: unique case (transfer_address[5:2])
          4'd0: HRDATA = {12'd0, display_digits};
          4'd1: HRDATA = {27'd0, display_enable};
          default: HRDATA = 32'd0;
        endcase
        UART_PAGE: unique case (transfer_address[5:2])
          4'd0: HRDATA = {24'd0, uart_tx_data};
          4'd1: HRDATA = 32'd1;
          default: HRDATA = 32'd0;
        endcase
        default: HRDATA = 32'd0;
      endcase
    end
  end

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      transfer_pending <= 1'b0;
      transfer_address <= 32'd0;
      transfer_write <= 1'b0;
      transfer_size <= 3'd0;
      timer_control <= 32'd0;
      timer_reload <= 32'd0;
      timer_value <= 32'd0;
      timer_pending <= 1'b0;
      gpio_previous <= 2'd0;
      gpio_event <= 2'd0;
      gpio_irq_enable <= 2'd0;
      gpio_output <= 32'd0;
      gpio_direction <= 32'd0;
      display_digits <= 20'd0;
      display_enable <= 5'd0;
      uart_tx_valid <= 1'b0;
      uart_tx_data <= 8'd0;
    end else begin
      transfer_pending <= address_phase;
      uart_tx_valid <= 1'b0;
      gpio_previous <= gpio_input;

      // TODO(timer-registers): implement deterministic countdown, one-shot and
      // periodic reload, sticky pending, IRQ gating, and W1C acknowledgement.
      if (timer_control[0] && timer_value != 32'd0) timer_value <= timer_value - 32'd1;

      // TODO(gpio-sevenseg): latch rising input edges without losing a second
      // source when software acknowledges a different EVENT bit.
      gpio_event <= gpio_event | (gpio_input & ~gpio_previous);

      if (address_phase) begin
        transfer_address <= HADDR;
        transfer_write <= HWRITE;
        transfer_size <= HSIZE;
      end

      if (transfer_pending && transfer_write && word_access && known_page) begin
        unique case (transfer_address[31:16])
          TIMER_PAGE: unique case (transfer_address[5:2])
            4'd0: timer_control <= HWDATA;
            4'd1: begin timer_reload <= HWDATA; timer_value <= HWDATA; end
            4'd3: if (HWDATA[0]) timer_pending <= 1'b0;
            default: begin end
          endcase
          GPIO_PAGE: unique case (transfer_address[5:2])
            4'd0: gpio_output <= HWDATA;
            4'd1: gpio_direction <= HWDATA;
            4'd2: gpio_event <= gpio_event & ~HWDATA[1:0];
            4'd3: gpio_irq_enable <= HWDATA[1:0];
            default: begin end
          endcase
          DISPLAY_PAGE: unique case (transfer_address[5:2])
            4'd0: display_digits <= HWDATA[19:0];
            4'd1: display_enable <= HWDATA[4:0];
            default: begin end
          endcase
          UART_PAGE: if (transfer_address[5:2] == 4'd0) begin
            uart_tx_data <= HWDATA[7:0];
            uart_tx_valid <= 1'b1;
          end
          default: begin end
        endcase
      end
    end
  end

  logic _unused;
  always_comb _unused = TIMER_CLOCK_HZ[0];
endmodule
