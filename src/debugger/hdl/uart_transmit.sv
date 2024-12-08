`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600,
    parameter NUM_BITS = 8
  ) (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [NUM_BITS - 1 : 0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
  );
   
  localparam BAUD_BIT_PERIOD  = INPUT_CLOCK_FREQ/BAUD_RATE;
  localparam CTR_SIZE = $clog2(BAUD_BIT_PERIOD);
  localparam BIT_COUNT_WIDTH = $clog2(NUM_BITS + 2); // + 2 because of the necessity of the START and STOP bits

  logic [NUM_BITS : 0] transmit_data; 

  enum {IDLE, DATA} state; 

  logic count_done;

  cycle_counter #(.CTR_SIZE(CTR_SIZE)) counter (
    .clk_in(clk_in),
    .rst_in(rst_in || state == IDLE),
    .period_in(BAUD_BIT_PERIOD),
    .count_done(count_done)
  );

  logic [BIT_COUNT_WIDTH - 1:0] bit_count;

  evt_counter #(.MAX_COUNT(NUM_BITS + 2)) bit_counter (
      .clk_in(clk_in),
      .rst_in(rst_in || state != DATA),
      .evt_in(count_done),
      .count_out(bit_count)
  );

  logic all_bits_sent = (bit_count == NUM_BITS && count_done);

  assign busy_out = (state == DATA); // Busy when state == DATA

  always_ff @(posedge clk_in) begin

    if (rst_in) state <= IDLE; // Waiting for the data to be ready to send

    else begin
      if (state == IDLE && trigger_in) begin
        transmit_data <= {1'b1, data_byte_in}; // store the data in a buffer
        tx_wire_out <= 1'b0; // Send the START bit (0)
        state <= DATA; // Sending DATA
      
      end else if (state == DATA && count_done) begin
        tx_wire_out <= transmit_data[0]; // Send the LSB first
        transmit_data <= {1'b1, transmit_data[NUM_BITS : 1]}; // Cycle the transmit_data
        if (all_bits_sent) state <= IDLE; // Return to IDLE if the STOP bit is done sending

      end
    end
  end

   
endmodule // uart_transmit

`default_nettype wire
