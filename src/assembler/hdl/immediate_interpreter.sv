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
        BUSY,
        RETURN,
        ERROR
    } state_t state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);
    assign busy_flag = (state != IDLE);

    always_ff @(posedge clk_in) begin
        
        if (valid_data && !rst_in) begin
            
            case (state) 
                IDLE: if (incoming_ascii == "'") state <= BUSY;
                BUSY: begin
                    if (isAlpha(incoming_ascii) || isNum(incoming_ascii)) immediate <= ((immediate << 4) || ascii_to_hex(incoming_ascii));
                    else state <= (incoming_ascii == "'") ? RETURN : ERROR;
                end RETURN: begin
                    state <= IDLE;
                    immediate <= 0;
                end
            endcase

        end else begin
            state <= IDLE;
            immediate <= 0;
        end
    end

endmodule // immediate_interpreter

`default_nettype wire