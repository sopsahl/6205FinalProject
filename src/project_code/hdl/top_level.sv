`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock

  output logic [6:0] ss0_c,
  output logic [6:0] ss1_c,
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an
  );
  localparam SCREEN_WIDTH = 76;
  localparam SCREEN_HEIGHT = 44;

  assign led = sw;
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];

  //Clocking Variables:
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (.clk_pixel(clk_pixel),.clk_tmds(clk_5x),
          .reset(0), .locked(locked), .clk_ref(clk_100mhz));

  //signals related to driving the video pipeline
  logic [10:0] hcount;
  logic [9:0] vcount;
  logic vert_sync;
  logic hor_sync;
  logic active_draw;
  logic new_frame;
  logic [5:0] frame_count;

  //from week 04! (make sure you include in your hdl)
  video_sig_gen mvg(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));

  //x_com and y_com are the image sprite locations
  logic terminal_grid_write_enable;
  logic [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] terminal_grid_addr;
  logic [7:0] terminal_grid_input;

  logic [$clog2(SCREEN_WIDTH)-1:0] cursor_x;
  logic [$clog2(SCREEN_HEIGHT)-1:0] cursor_y;
  logic [1:0] x_btn;
  logic [1:0] y_btn;
  logic [1:0] bksp_btn;

  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_pixel) begin
    if (sys_rst) begin
      cursor_x <= 0;
      cursor_y <= 0;
      terminal_grid_write_enable <= 0;
      terminal_grid_addr <= 0;
      terminal_grid_input <= 0;
    end else begin
      terminal_grid_write_enable <= 0;
      x_btn[1] <= x_btn[0];
      y_btn[1] <= y_btn[0];
      bksp_btn[1] <= bksp_btn[0];

      if (bksp_btn[1] && !bksp_btn[0] && !(cursor_x == 0 && cursor_y == 0)) begin
          terminal_grid_write_enable <= 1;
          terminal_grid_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
          terminal_grid_input <= 0;

        if (cursor_x == 0) begin
          cursor_y <= cursor_y - 1;
          cursor_x <= SCREEN_WIDTH - 1;
        end else begin
          cursor_x <= cursor_x - 1;
        end
      end else begin
        if (x_btn[1] && !x_btn[0] && cursor_x < SCREEN_WIDTH) begin
          terminal_grid_write_enable <= 1;
          terminal_grid_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
          terminal_grid_input <= sw;
          cursor_x <= cursor_x + 1;
        end

        if (y_btn[1] && !y_btn[0] && cursor_y < SCREEN_HEIGHT) begin
          terminal_grid_write_enable <= 1;
          terminal_grid_addr <= cursor_y * SCREEN_WIDTH + cursor_x;
          terminal_grid_input <= sw;
          cursor_x <= 0;
          cursor_y <= cursor_y + 1;
        end
      end
    end
  end

  debouncer #(
    .CLK_PERIOD_NS(10),
    .DEBOUNCE_TIME_MS(5))
  x_b (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .dirty_in(btn[1]),
    .clean_out(x_btn[0]));

  debouncer #(
    .CLK_PERIOD_NS(10),
    .DEBOUNCE_TIME_MS(5))
  y_b (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .dirty_in(btn[2]),
    .clean_out(y_btn[0]));

  debouncer #(
    .CLK_PERIOD_NS(10),
    .DEBOUNCE_TIME_MS(5))
  bksp_b (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .dirty_in(btn[3]),
    .clean_out(bksp_btn[0]));

  //use this in the first part of checkoff 01:
  //instance of image sprite.
  logic [7:0] img_red, img_green, img_blue;

  character_sprite #(
  .SIZE(16),
  .HEIGHT(512),
  .SCREEN_WIDTH(SCREEN_WIDTH),
  .SCREEN_HEIGHT(SCREEN_HEIGHT))
  com_sprite_m (
  .pixel_clk_in(clk_pixel),
  .rst_in(sys_rst),
  .tg_write_en(terminal_grid_write_enable),
  .tg_addr(terminal_grid_addr),
  .tg_input(terminal_grid_input),
  .hcount_in(hcount),
  .vcount_in(vcount), // what is this for? x_com>128 ? x_com-128 : 0
  .red_out(img_red),
  .green_out(img_green),
  .blue_out(img_blue));

  logic [7:0] red, green, blue;

  assign red = img_red;
  assign green = img_green;
  assign blue = img_blue;

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!

  //three tmds_encoders (blue, green, red)
  //blue should have {vert_sync and hor_sync for control signals)
  //red and green have nothing
  tmds_encoder tmds_red(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(red),
    .control_in(2'b0),
    .ve_in(active_draw),
    .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(green),
    .control_in(2'b0),
    .ve_in(active_draw),
    .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(blue),
    .control_in({vert_sync,hor_sync}),
    .ve_in(active_draw),
    .tmds_out(tmds_10b[0]));

  //four tmds_serializers (blue, green, red, and clock)
  tmds_serializer red_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[2]),
    .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[1]),
    .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[0]),
    .tmds_out(tmds_signal[0]));

  //output buffers generating differential signal:
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

  assign ss0_c = 0; //ss_c; //control upper four digit's cathodes!
  assign ss1_c = 0; //ss_c; //same as above but for lower four digits!

endmodule // top_level


`default_nettype wire