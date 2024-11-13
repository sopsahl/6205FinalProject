`timescale 1ns / 1ps
`default_nettype none

module cycle_counter #(
    parameter CTR_SIZE = 32 
)(     
    input wire clk_in,
    input wire rst_in,
    input wire [CTR_SIZE - 1:0] period_in,
    output logic count_done
);
  
  logic [CTR_SIZE - 1:0] count;


  always_ff @(posedge clk_in) begin

    if (rst_in) begin
        count <= 0; // Reset the count
        count_done <= 1'b0; // Reset the output

    end else begin
        count <= (count == period_in - 1) ? 0 : count + 1;
        count_done <= (count == period_in - 1);

    end

  end

endmodule // cycle counter

`default_nettype wire