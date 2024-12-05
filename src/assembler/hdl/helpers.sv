`timescale 1ns / 1ps
`default_nettype none

module  evt_counter #( 
    parameter MAX_COUNT = 256 
)(   
    input wire clk_in,
    input wire rst_in,
    input wire evt_in,
    output logic [$clog2(MAX_COUNT) - 1:0] count_out
);

    always_ff @(posedge clk_in) begin
        if (rst_in) count_out <= 0;
        else if (evt_in) count_out <= (count_out == MAX_COUNT - 1) ? 0 : count_out + 1;
    end

endmodule // evt_counter


`default_nettype wire