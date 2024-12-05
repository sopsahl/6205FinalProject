`timescale 1ns / 1ps
`default_nettype none

// immediate_interpreter: takes the immediate value (0 - FF_FF_FF_FF)
// Up to 4 bytes of data (8 characters)
// Calculates the immediate output 
// Takes until the end of the 

import assembler_constants::*;

module immediate_interpreter (
    input wire clk_in,
    input wire rst_in,
    input wire valid_data,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,
    output logic busy_flag,

    output logic [31:0] immediate
);

    typedef enum {
        IDLE, 
        FIRST_NUM,
        BUSY,
        RETURN,
        ERROR
    } state_t state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);
    assign busy_flag = (state != IDLE);

    logic isValid;
    assign isValid = isAlpha(incoming_ascii) || isNum(incoming_ascii);

    logic [3:0] hex;
    assign hex = ascii_to_hex(incoming_ascii);

    always_ff @(posedge clk_in) begin
        
        if (valid_data && !rst_in) begin
            
            case (state) 
                IDLE: if (incoming_ascii == "x" || incoming_ascii == "X") state <= FIRST_NUM;
                FIRST_NUM: begin
                    if (isValid) begin
                        state <= BUSY;
                        immediate <= {28{hex[3]}, hex}; // Extend the MSB
                    end else state <= IDLE;
                end BUSY: begin
                    if (isValid) immediate <= ((immediate << 4) || hex);
                    else state <= (incoming_ascii == " " || incoming_ascii == ",") ? RETURN : ERROR;
                end RETURN: state <= IDLE;
            endcase

        end else state <= IDLE;
    end

endmodule // immediate_interpreter

`default_nettype wire