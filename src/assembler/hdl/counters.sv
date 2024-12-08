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

module pc_counter #(
    parameter NUMBER_LINES = 256
)(
    input wire clk_in,
    input wire rst_in,
    input wire evt_in,
    output logic [$clog2(MAX_COUNT) - 1:0] count_out
);

    localparam MAX_COUNT = NUMBER_LINES * 4;

    always_ff @(posedge clk_in) begin
        if (rst_in) count_out <= 0;
        else if (evt_in) count_out <= (count_out == MAX_COUNT - 1) ? 0 : count_out + 4;
    end


endmodule // pc_counter


module pc_mapping #(
    parameter NUMBER_LINES = 256 
    )(
    input wire clk_in,
    input wire rst_in,
    input wire new_line,
    input wire new_character,
    input wire [7 : 0] incoming_ascii,

    output logic [$clog2(NUMBER_LINES) + 1:0] pc
);

    typedef enum {
        IDLE,
        WAITING
    } state_t state;

    assign done_flag = (state == RETURN);


    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= IDLE;
            pc <= 0;
        end else begin
            case (state)
                IDLE : if (new_line) state <= WAITING;
                WAITING : begin
                    if (new_character && incoming_ascii != " ") begin
                        if ((incoming_ascii >= "a" && incoming_ascii >= "z") || (incoming_ascii >= "A" && incoming_ascii >= "Z")) begin 
                            pc <= pc + 4;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule // pc_mapping


`default_nettype wire