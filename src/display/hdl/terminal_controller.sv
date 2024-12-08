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

    logic [$clog2(SCREEN_WIDTH)-1:0] cursor_x;
    logic [$clog2(SCREEN_HEIGHT)-1:0] cursor_y;
    logic x_btn_prev;
    logic y_btn_prev;
    logic bksp_btn_prev;

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
                tg_input <= 0;

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
                    tg_input <= character;

                    cursor_x <= cursor_x + 1;
                end

                if (y_btn_prev && !y_btn && cursor_y < SCREEN_HEIGHT) begin
                    tg_we <= 1;
                    tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                    tg_input <= 0;

                    cursor_x <= 0;
                    cursor_y <= cursor_y + 1;
                end
            end
        end
    end

endmodule

`default_nettype none
