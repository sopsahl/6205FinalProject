`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module input_buffer (
    input wire clk_in,
    input wire clk_two,
    input wire rst_in,
    input wire data_in,
    output logic key_pressed,
    output logic enter_pressed,
    output logic bksp_pressed,
    output logic [15:0] character
  );
    logic a;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            a <= 0;
        end else begin
            if (!data_in) begin
                enter_pressed <= a;
                a <= !a;
            end
        end
    end
  /*
    enum {START, DATA, PARITY, STOP, SEND} state;

    logic [6:0] data;
    logic [15:0] d2c;
    logic [2:0] data_counter;
    logic has_odd_parity;
    logic [4:0] char_pos;

    assign has_odd_parity = ~(^{data, data_in});

    always_comb begin
        // converts data to sprite characters
        // a = 1, b = 2, c = 3, etc... (uses ascii!!!)
        case(data)
            'h15: d2c = 113;
            'h1d: d2c = 119;
            'h24: d2c = 101;
            'h2d: d2c = 114;
            'h2c: d2c = 116;
            'h35: d2c = 121;
            'h3c: d2c = 117;
            'h43: d2c = 105;
            'h44: d2c = 111;
            'h4d: d2c = 112;
            'h1c: d2c = 97;
            'h1b: d2c = 115;
            'h23: d2c = 100;
            'h2b: d2c = 102;
            'h34: d2c = 103;
            'h33: d2c = 104;
            'h3b: d2c = 106;
            'h42: d2c = 107;
            'h4b: d2c = 108;
            'h1a: d2c = 122;
            'h22: d2c = 120;
            'h21: d2c = 99;
            'h2a: d2c = 118;
            'h32: d2c = 98;
            'h31: d2c = 110;
            'h3a: d2c = 109;
            'h16: d2c = 49;
            'h1e: d2c = 50;
            'h26: d2c = 51;
            'h25: d2c = 52;
            'h2e: d2c = 53;
            'h36: d2c = 54;
            'h3d: d2c = 55;
            'h3e: d2c = 56;
            'h46: d2c = 57;
            'h45: d2c = 48;
            'h41: d2c = 44; // comma
            'h49: d2c = 46; // period
            'h29: d2c = 32; // space
            'h5a: d2c = 10; // enter
            'h66: d2c = 62; // bksp
            default: d2c = 32;
        endcase

        // state outputs
        case(state)
            SEND: begin
                if (d2c == 28) begin // enter
                    enter_pressed = 1;
                    key_pressed = 0;
                    bksp_pressed = 0;
                    character = 0;
                    is_instr_complete = 1;
                end else if (d2c == 27) begin // bksp
                    bksp_pressed = 1;
                    key_pressed = 0;
                    enter_pressed = 0;
                    character = 0;
                    is_instr_complete = 0;
                end else begin
                    key_pressed = 1;
                    character = d2c;
                    enter_pressed = 0;
                    bksp_pressed = 0;
                    is_instr_complete = 0;
                    curr_instr[char_pos] = d2c;
                end
            end
            default: begin
                key_pressed = 0;
                enter_pressed = 0;
                bksp_pressed = 0;
                character = 0;
                is_instr_complete = 0;
            end
        endcase
    end

    // state transitions (on negedge of clock, NOT posedge)
    always_ff @(negedge clk_in) begin
        if (rst_in) begin
            state <= START;
            data <= 0;
            data_counter <= 0;
            char_pos <= 0;
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
                SEND: begin
                    state <= START;
                    // manages the pointer for storing the instruction
                    if (d2c == 28) begin
                        char_pos <= 0;
                    end else if (d2c == 27) begin
                        char_pos <= char_pos - 1;
                    end else begin
                        char_pos <= char_pos + 1;
                    end
                end
                default: state <= START;
            endcase
        end
    end*/
endmodule

`default_nettype none
