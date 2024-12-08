`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600,
    parameter NUM_BITS = 8
  ) (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [NUM_BITS - 1:0] data_byte_out
  );

  localparam UART_DATA_PERIOD  = INPUT_CLOCK_FREQ/BAUD_RATE;
  localparam UART_START_PERIOD = UART_DATA_PERIOD/2 - 1; // Minus 1 because of a cycle delay from cycle_counter reset 
  localparam UART_STOP_PERIOD = UART_DATA_PERIOD/4;
  localparam MAX_CTR_SIZE = $clog2(UART_DATA_PERIOD);
  localparam BIT_COUNT_WIDTH = $clog2(NUM_BITS + 1); // + 1 because of the necessity of the STOP bit

  logic count_done;
  
  logic [MAX_CTR_SIZE - 1 : 0] cycle_period;
  assign cycle_period = (state == START) ? UART_START_PERIOD : (state == STOP) ? UART_STOP_PERIOD : UART_DATA_PERIOD;
  
  cycle_counter #(.CTR_SIZE(MAX_CTR_SIZE)) counter (
    .clk_in(clk_in),
    .rst_in(rst_in || state == IDLE),
    .period_in(cycle_period),
    .count_done(count_done)
  );

  logic [BIT_COUNT_WIDTH - 1:0] bit_count;

  evt_counter #(.MAX_COUNT(NUM_BITS + 1)) bit_counter (
      .clk_in(clk_in),
      .rst_in(rst_in || state != DATA),
      .evt_in(count_done),
      .count_out(bit_count)
  );

  enum {IDLE, START, DATA, STOP, DONE} state;

  assign new_data_out = (state == DONE); // Data is valid if state is DONE
  
  logic all_bits_received;
  assign all_bits_received = (bit_count == NUM_BITS && count_done); // Once we have the last count, pulse all_bits_received

  always_ff @(posedge clk_in) begin
    
    if (rst_in) state <= IDLE; // We are idling, waiting for input
    
    else begin

      if (state == IDLE && !rx_wire_in) state <= START; // Transition to START if we detect a start bit (0)

      else if (state == START) state <= (rx_wire_in) ? IDLE : (count_done) ? DATA : START; // Transition to DATA if start bit has remained valid
      
      else if (state == DATA && count_done) begin
          if (all_bits_received) state <= (rx_wire_in) ? STOP : IDLE; // Transition to STOP if all data received and stop bit valid (1)
          else data_byte_out <= {rx_wire_in, data_byte_out[NUM_BITS - 1:1]}; // Store the received bit

      end else if (state == STOP) state <= (!rx_wire_in) ? IDLE : (count_done) ? DONE : STOP; // Transition to DONE if stop bit remains valid

      else if (state == DONE) state <= IDLE; // DONE only lastes for one cycle

    end 
  end

endmodule // uart_receive

`default_nettype wire
