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
  output logic [7:0] tg_input,
  output logic scroll_up,
  output logic scroll_down
  );

    logic [7:0] char2ascii;
    logic [$clog2(SCREEN_WIDTH)-1:0] cursor_x;
    logic [$clog2(SCREEN_HEIGHT)-1:0] cursor_y;
    logic x_btn_prev;
    logic y_btn_prev;
    logic bksp_btn_prev;
    logic [3:0] status_update;
    logic [7:0][7:0] compiling_msg;
    logic [7:0][7:0] idling_msg;

    always_comb begin
        case (character[5:0])
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
            32: char2ascii = 44;
            33: char2ascii = 46;
            34: char2ascii = 35;
            35: char2ascii = 49;
            36: char2ascii = 50;
            37: char2ascii = 51;
            38: char2ascii = 52;
            39: char2ascii = 53;
            40: char2ascii = 54;
            41: char2ascii = 55;
            42: char2ascii = 56;
            43: char2ascii = 57;
            44: char2ascii = 48;
            45: char2ascii = 124;
            46: char2ascii = 38;
            47: char2ascii = 47;
            48: char2ascii = 32; // enter
            49: char2ascii = 0;  // scroll up
            50: char2ascii = 1;  // scroll down
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
            status_update <= 0;

            compiling_msg[0] <= 32;
            compiling_msg[1] <= 99;
            compiling_msg[2] <= 111;
            compiling_msg[3] <= 109;
            compiling_msg[4] <= 112;
            compiling_msg[5] <= 105;
            compiling_msg[6] <= 108;
            compiling_msg[7] <= 101;

            idling_msg[0] <= 32;
            idling_msg[1] <= 105;
            idling_msg[2] <= 100;
            idling_msg[3] <= 108;
            idling_msg[4] <= 105;
            idling_msg[5] <= 110;
            idling_msg[6] <= 103;
            idling_msg[7] <= 32;
        end else begin
            tg_we <= 0;
            x_btn_prev <= x_btn;
            y_btn_prev <= y_btn;
            bksp_btn_prev <= bksp_btn;
            scroll_up <= 0;
            scroll_down <= 0;

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
                    if (char2ascii == 0) begin
                        scroll_down <= 1;
                    end else if (char2ascii == 1) begin
                        scroll_up <= 1;
                    end else begin
                        tg_we <= 1;
                        tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                        tg_input <= char2ascii;

                        cursor_x <= cursor_x + 1;
                    end
                end

                if (status_update != 0) begin
                    if (status_update == 8) begin
                        status_update <= 0;
                    end else begin
                        status_update <= status_update + 1;
                        tg_we <= 1;
                        tg_addr <= 42 * SCREEN_WIDTH + (status_update);

                        if (character[15] == 1) begin
                            tg_input <= compiling_msg[status_update];
                        end else if (character[14] == 1) begin
                            tg_input <= idling_msg[status_update];
                        end
                    end
                end
                
                if (y_btn_prev && !y_btn) begin
                    if (cursor_y < SCREEN_HEIGHT) begin
                        if ((character[15] == 1 || character[14] == 1) && status_update < 8) begin 
                            status_update <= status_update + 1;
                        end else begin
                            tg_we <= 1;
                            tg_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
                            tg_input <= char2ascii;

                            cursor_x <= 0;
                            cursor_y <= cursor_y + 1;
                            status_update <= 0;
                        end
                    end
                end
            end
        end
    end

endmodule

`default_nettype none
