`timescale 1ns / 1ps
`default_nettype none

// register_interpreter: takes the register number (00 - 31) 
// and calculates the register number (5 bits)
// done_flag high same cycle as delimiter (" " or ",")

import constants::*;

module register_interpreter (
    input wire clk_in,
    input wire rst_in,
    input wire valid_data,
    input wire new_character,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,

    output logic [4:0] register
);

    enum {
        IDLE, 
        FIRST_DIGIT,
        SECOND_DIGIT,
        VALIDATION,
        RETURN,
        ERROR
    } state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);

    always_ff @(posedge clk_in) begin

        if (valid_data && !rst_in) begin
            if (new_character) begin
                case (state) 
                    IDLE: if (incoming_ascii == "r" || incoming_ascii == "R") state <= FIRST_DIGIT;
                    FIRST_DIGIT: begin
                        register <= (incoming_ascii[1:0] << 1) + (incoming_ascii[1:0] << 3); // 10x
                        state <= (incoming_ascii >= "0" && incoming_ascii <= "3") ? SECOND_DIGIT : ERROR;
                    end SECOND_DIGIT: begin
                        register <= register + incoming_ascii[3:0]; 
                        state <= ((incoming_ascii >= "0" && incoming_ascii <= "9") && !(register >= 30 && incoming_ascii[3:0] >= 2)) ? RETURN : ERROR;
                    end VALIDATION: state <= (incoming_ascii == " " || incoming_ascii == ",") ? RETURN : ERROR;
                endcase
            end else if (state == RETURN) state <= IDLE;

        end else state <= IDLE;
    end

endmodule // register_interpreter

`default_nettype wire
