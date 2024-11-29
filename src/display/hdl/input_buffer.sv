`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module input_buffer (
    input wire clk_in,
    input wire rst_in,
    input wire data_in,
    output logic key_pressed,
    output logic enter_pressed,
    output logic bksp_pressed,
    output logic [15:0] character
  );
    enum {START, DATA, PARITY, STOP, SEND} state;

    logic [6:0] data;
    logic [15:0] d2c;
    logic [2:0] data_counter;
    logic has_odd_parity;

    assign has_odd_parity = ~(^{data, data_in});

    always_comb begin
        // converts data to sprite characters
        // a = 1, b = 2, c = 3, etc...
        case(data)
            'h15: d2c = 17;
            'h1d: d2c = 23;
            'h24: d2c = 5;
            'h2d: d2c = 18;
            'h2c: d2c = 20;
            'h35: d2c = 25;
            'h3c: d2c = 21;
            'h43: d2c = 9;
            'h44: d2c = 15;
            'h4d: d2c = 16;
            'h1c: d2c = 1;
            'h1b: d2c = 19;
            'h23: d2c = 4;
            'h2b: d2c = 6;
            'h34: d2c = 7;
            'h33: d2c = 8;
            'h3b: d2c = 10;
            'h42: d2c = 11;
            'h4b: d2c = 12;
            'h1a: d2c = 26;
            'h22: d2c = 24;
            'h21: d2c = 3;
            'h2a: d2c = 22;
            'h32: d2c = 2;
            'h31: d2c = 14;
            'h3a: d2c = 13;
            'h29: d2c = 0; // space
            'h5a: d2c = 28; // enter
            'h66: d2c = 27; // bksp
            default: d2c = 0;
        endcase

        // state outputs
        case(state)
            SEND: begin
                if (d2c == 28) begin // enter
                    enter_pressed = 1;
                    key_pressed = 0;
                    bksp_pressed = 0;
                    character = 0;
                end else if (d2c == 27) begin // bksp
                    bksp_pressed = 1;
                    key_pressed = 0;
                    enter_pressed = 0;
                    character = 0;
                end else begin
                    key_pressed = 1;
                    character = d2c;
                    enter_pressed = 0;
                    bksp_pressed = 0;
                end
            end
            default: begin
                key_pressed = 0;
                enter_pressed = 0;
                bksp_pressed = 0;
                character = 0;
            end
        endcase
    end

    // state transitions (on negedge of clock, NOT posedge)
    always_ff @(negedge clk_in) begin
        if (rst_in) begin
            state <= START;
            data <= 0;
            data_counter <= 0;
        end else begin
            case(state)
                START: begin
                    data <= 0;
                    state <= !data_in ? DATA : START;
                end
                DATA: begin
                    data[data_counter] <= data_in;
                    if (data_counter == 6) begin
                        state <= PARITY;
                        data_counter <= 0;
                    end else begin
                        state <= DATA;
                        data_counter <= data_counter + 1;
                    end
                end
                PARITY: state <= has_odd_parity ? STOP : START;
                STOP: state <= data_in ? SEND : START;
                SEND: state <= START;
                default: state <= START;
            endcase
        end
    end
endmodule

`default_nettype none
