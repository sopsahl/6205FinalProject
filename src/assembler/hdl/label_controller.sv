`timescale 1ns / 1ps
`default_nettype none

module label_controller #(
    parameter NUMBER_LINES = 256
    ) (     
    input wire clk_in,
    input wire rst_in,
    input wire new_line, 
    input wire new_character,
    input wire [$clog2(NUMBER_LINES) - 1 : 0] pc,
    input wire [7:0] incoming_character, // Each new character 
    output logic done_flag, // Instruction is Ready
    output wire 
    output logic error_flag, // Error encountered

    input assembler_state assembler_state, // Determines what we are doing at any given point
    output logic [31:0] instruction
);  
    


endmodule

`default_nettype wire