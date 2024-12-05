`timescale 1ns / 1ps
`default_nettype none

// register_interpreter: takes the register number (00 - 31) 
//  and calculates the register number (5 bits)
//  Takes 2 cycles pipelined

import assembler_constants::*;

module register_interpreter (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,
    output logic busy_flag,

    output logic [4:0] register
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

    assign error_flag = (state == ERROR);

    always_ff @(posedge clk_in) begin
        
        if (rst_in) begin
            state <= IDLE;
            register <= 0;

        end else begin
            case (state) 
                IDLE: begin
                    if (trigger_in) begin
                        if (!incoming_ascii >= "0" || !incoming_ascii <= "3") state <= ERROR; // out of bounds
                        else begin
                            state <= BUSY;
                            register <= (incoming_ascii[1:0] << 1) + (incoming_ascii[1:0] << 3); // 10x
                        end
                    end
                end BUSY: begin
                    if (incoming_ascii >= "0" && incoming_ascii <= "9") begin
                        if (register >= 30 && incoming_ascii[3:0] >= 2) state <= ERROR; // out of bounds
                        else begin
                            state <= RETURN;
                            register <= register + incoming_ascii[3:0]; 
                        end
                    end else state <= ERROR;
                end RETURN: state <= (incoming_ascii == " " || incoming_ascii == ",") ? IDLE : ERROR;
            endcase
        end
    end

endmodule // register_interpreter

`default_nettype wire
