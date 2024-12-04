`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module terminal_controller #(
  parameter SCREEN_WIDTH=76, SCREEN_HEIGHT=44) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire x_btn,
  input wire y_btn,
  input wire bksp_btn,
  input wire [15:0] character,
  output logic tg_we,
  output logic [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] tg_addr,
  output logic [7:0] tg_input
  );

    logic [7:0] char2ascii;
    logic [$clog2(SCREEN_WIDTH)-1:0] cursor_x;
    logic [$clog2(SCREEN_HEIGHT)-1:0] cursor_y;
    logic x_btn_prev;
    logic y_btn_prev;
    logic bksp_btn_prev;

    always_comb begin
        case (character)
            0: char2ascii = 32;
            1: char2ascii = 97;
            2: char2ascii = 98;
            3: char2ascii = 99;
            4: char2ascii = 100;
            5: char2ascii = 101;
            6: char2ascii = 102;
            7: char2ascii = 103;
            8: char2ascii = 104;
            9: char2ascii = 105;
            10: char2ascii = 106;
            11: char2ascii = 107;
            12: char2ascii = 108;
            13: char2ascii = 109;
            14: char2ascii = 110;
            15: char2ascii = 111;
            16: char2ascii = 112;
            17: char2ascii = 113;
            18: char2ascii = 114;
            19: char2ascii = 115;
            20: char2ascii = 116;
            21: char2ascii = 117;
            22: char2ascii = 118;
            23: char2ascii = 119;
            24: char2ascii = 120;
            25: char2ascii = 121;
            26: char2ascii = 122;
            27: char2ascii = 60;
            28: char2ascii = 62;
            29: char2ascii = 40;
            30: char2ascii = 41;
            31: char2ascii = 61;
            default: char2ascii = 32;
        endcase
    end

    //update center of mass x_com, y_com based on new_com signal
    always_ff @(posedge pixel_clk_in) begin
        if (rst_in) begin
            cursor_x <= 0;
            cursor_y <= 0;
            x_btn_prev <= 0;
            y_btn_prev <= 0;
            bksp_btn_prev <= 0;
        end else begin
            tg_we <= 0;
            x_btn_prev <= x_btn;
            y_btn_prev <= y_btn;
            bksp_btn_prev <= bksp_btn;

            if (bksp_btn_prev && !bksp_btn && !(cursor_x == 0 && cursor_y == 0)) begin
                tg_we <= 1;
                tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                tg_input <= 32;

                if (cursor_x == 0) begin
                    cursor_y <= cursor_y - 1;
                    cursor_x <= SCREEN_WIDTH - 1;
                end else begin
                    cursor_x <= cursor_x - 1;
                end
            end else begin
                if (x_btn_prev && !x_btn && cursor_x < SCREEN_WIDTH) begin
                    tg_we <= 1;
                    tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                    tg_input <= char2ascii;

                    cursor_x <= cursor_x + 1;
                end

                if (y_btn_prev && !y_btn && cursor_y < SCREEN_HEIGHT) begin
                    tg_we <= 1;
                    tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                    tg_input <= 60;

                    cursor_x <= 0;
                    cursor_y <= cursor_y + 1;
                end
            end
        end
    end

endmodule

`default_nettype none
