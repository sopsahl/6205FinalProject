`timescale 1ns / 1ps
`default_nettype none

import assembler_constants::*;

module instruction_by_line #(
    parameter CHAR_PER_LINE = 64
    ) (     
    input wire clk_in,
    input wire rst_in,
    input wire new_line, // Restart the logic
    input wire new_character,
    input wire [7:0] incoming_character, // Each new character    
    output logic [31:0] instruction,
    output logic done_flag, // Instruction is Ready
    output logic error_flag, // Error encountered
    output logic busy_flag
);

    assign ready_flag = (state == DONE);
    assign error_flag = (
        !rst_in 
        // || new_character 
        || (new_line && !ready_flag)
        );

    // State Logic
    typedef enum {
        IDLE,
        READ_INST,
        READ_RD,
        READ_RS1,
        READ_RS2,
        READ_IMM,
        READ_LABEL,
        ERROR,
        DONE
    } state_t state;

    
    assign error_flag = (state == ERROR);
    assign done_flag = (state == DONE);
    assign busy_flag = (state != IDLE);

    // typedef enum {
    //     IDLE,
    //     READ
    // }

    state_t state;
    state_t state_sequence[4];
    logic [2:0] state_index;

    InstFields inst; // stores all of the known values up until now

    always_ff @(posedge clk_in) begin

            if (rst_in) begin
                state <= IDLE;
                ready_flag <= 1'b0;
                error_flag <= 1'b0;
            end else begin
                case (state) 
                    IDLE: begin // Waiting for a new line
                        if (new_line) 
                    end READ_INST: begin

                    end READ_REG: begin

                    end READ_IMM: begin

                    end READ_LABEL: begin
                        
                    end DONE: begin

                    end 

                    end

                endcase

                count <= (count == period_in - 1) ? 0 : count + 1;
                count_done <= (count == period_in - 1);

            end

        end

    endmodule 

`default_nettype wire

    // logic [$clog2(CHAR_PER_LINE)] char_count;

    // evt_counter #(.MAX_COUNT(CHAR_PER_LINE)) char_counter (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in || new_line),
    //     .evt_in(character_valid),
    //     .count_out(char_count)

    // )