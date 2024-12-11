`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */


import constants::*;

module top_level(
  input wire clk_100mhz, //
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, // ASSEMBLER STATE
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock

  output logic [6:0] ss0_c,
  output logic [6:0] ss1_c,
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an,

  input wire data,
  input wire dclk
  );
  localparam SCREEN_WIDTH = 64;
  localparam SCREEN_HEIGHT = 256;
  

  assign led = sw;
  //shut up those rgb LEDs (active high):
  // assign rgb1= 0;
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

  logic buffer_x;
  logic buffer_y;
  logic buffer_bksp;
  logic [7:0] keyboard_char;
  logic is_instr_complete;
  logic [31:0][4:0] curr_instr;
  logic break_entered;

  ps2_keyboard_interface(
    .clk(clk_pixel), // FPGA clock
    .rst(sys_rst), // Synchronous reset
    .ps2_clk(dclk), // PS/2 clock from keyboard
    .ps2_data(data), // PS/2 data from keyboard
    .data_out(keyboard_char), // Decoded data output
    .key_pressed(buffer_x), // Data valid signal
    .enter_pressed(buffer_y),
    .bksp_pressed(buffer_bksp),
    .break_entered(break_entered)
  );

  

  logic [15:0] buffer_char;

  translate_keypress(
    .keypress(keyboard_char),
    .char(buffer_char)
  );

  // keeps track of what to input to the sprite drawer
  logic terminal_grid_write_enable;
  logic [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] terminal_grid_addr;
  logic [7:0] terminal_grid_input;
  logic up;
  logic down;
  logic[7:0] break_code;
  assign break_code = 8'hF0;

 typedef enum logic[1:0]{
  KEY,
  BREAK,
  ENTER,
  BKSP
 } key_type;
 key_type last_valid_key;
 always_ff @(posedge clk_pixel) begin
  if(buffer_x) begin
    last_valid_key<=  KEY;
  end
  else if(buffer_y) begin
    last_valid_key<= ENTER;
  end
  else if(buffer_bksp) begin
    last_valid_key<= BKSP;
  end
  else if(break_entered) begin
    last_valid_key <= BREAK;
  end
  else begin 


  end 
 end

  // DOWNCYCLING

  localparam FULL_CYCLE= 1<<16;
  localparam HALF_DOWN_CYCLE = ( FULL_CYCLE>>1 );
  logic [$clog2(FULL_CYCLE)-1:0] down_cycler_counter;
  logic down_clk;
  always_ff @(posedge clk_pixel) begin
    if(!down_cycler_counter)begin 
      down_cycler_counter<=1;
    end 
    else begin 
      down_cycler_counter<=down_cycler_counter+1;
    end
  end

  logic translation_done;

  assign down_clk = (! down_cycler_counter || down_cycler_counter < HALF_DOWN_CYCLE);
  logic enable_processor;
  logic [31:0] last_pc_program;
  logic [31:0] last_pc_executed;
  logic processor_done;
  logic [6:0] ss_c;
  //SIGNALS for outside BRAMs writes;
  logic processor_write_enable;
  logic [31:0] processor_write_data;
  logic [31:0] processor_write_address;

  // *********************************
  // PROCESSOR

  riscv_processor pr(
    .clk(down_clk),
    .rst(enable_processor || assembler_state != SUCCESS),
    .pixel_clk_in(clk_pixel),
    .ending_pc(last_pc_program),
    .instruction_write_address(num_instructions),
    .instruction_write_data(new_instruction),
    .instruction_write_enable(assembler_new_inst),
    .pc_out(last_pc_executed),
    .instruction_done(processor_done),
    .write_enable(processor_write_enable),
    .w_data(processor_write_data),
    .w_addr(processor_write_address)
  );

  // ****************************************

  terminal_controller #(
    .SCREEN_WIDTH(SCREEN_WIDTH),
    .SCREEN_HEIGHT(SCREEN_HEIGHT)
  ) terminal (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .x_btn((buffer_x && last_valid_key == BREAK)),
    .y_btn((buffer_y && last_valid_key == BREAK)),
    .bksp_btn(( buffer_bksp && last_valid_key == BREAK)),
    .character({sw[15:12], buffer_char[11:0]}),
    .tg_we(terminal_grid_write_enable),
    .tg_addr(terminal_grid_addr),
    .tg_input(terminal_grid_input),
    .scroll_up(up),
    .scroll_down(down)
  );

  //use this in the first part of checkoff 01:
  //instance of image sprite.
  logic [7:0] img_red, img_green, img_blue;

  character_sprites #(
    .SIZE(16),
    .HEIGHT(1024),
    .SCREEN_WIDTH(SCREEN_WIDTH),
    .SCREEN_HEIGHT(SCREEN_HEIGHT))
  draw_characters (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .scroll_up(up),
    .scroll_down(down),
    .tg_write_en(terminal_grid_write_enable),
    .tg_addr(terminal_grid_addr),
    .tg_input(terminal_grid_input),
    .hcount_in(hcount),
    .vcount_in(vcount), // what is this for? x_com>128 ? x_com-128 : 0
    .red_out(img_red),
    .green_out(img_green),
    .blue_out(img_blue)
  );

  logic [7:0] mmo_red, mmo_green, mmo_blue;

  visualizer #(
    .SIZE(16),
    .HEIGHT(1024),
    .SCREEN_WIDTH(SCREEN_WIDTH),
    .SCREEN_HEIGHT(42))
  mmo_visualizer (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .tg_write_en((processor_write_enable)), // TODO: get values from processor running
    .tg_addr(processor_write_address),  // TODO: get values from processor running
    .tg_input(processor_write_data), 
    .tg_proc_clk(down_clk), // TODO: get values from processor running
    .hcount_in(hcount),
    .vcount_in(vcount), // what is this for? x_com>128 ? x_com-128 : 0
    .red_out(mmo_red),
    .green_out(mmo_green),
    .blue_out(mmo_blue)
  );

  logic [7:0] red, green, blue;

  assign red = sw[11] ? mmo_red : img_red;
  assign green = sw[11] ? mmo_green : img_green;
  assign blue = sw[11] ? mmo_blue : img_blue;

  // *************************************************
  // ASSEMBLY AND TEXT EDITOR

  logic [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] text_editor_addr;
  logic [7:0] text_editor_output;

  logic assembler_trigger;
  debouncer #(
    .CLK_PERIOD_NS(10),
    .DEBOUNCE_TIME_MS(5))
  assembler_trig (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .dirty_in(btn[1]),
    .clean_out(assembler_trigger));

  assembler_state_t assembler_state = IDLE;
  
  enum {
    OFF,
    START,
    SENDING_CHARS,
    NEW_LINE
  } text_transmission_state;

  logic [$clog2(SCREEN_HEIGHT) - 1:0] assembler_y;
  logic [2:0][$clog2(SCREEN_WIDTH) - 1:0] assembler_x;
  logic [2:0] assembler_new_char;

  logic assembler_new_line;
  assign assembler_new_line = (text_transmission_state == NEW_LINE);

  logic assembler_line_done, assembler_line_error, assembler_new_inst;
  logic [31:0] new_instruction;

  assign text_editor_addr =  (assembler_y * SCREEN_WIDTH) + assembler_x[0]; // locates the point in memory
  assign rgb1 = (assembler_state == ERROR) ? 3'b100 : (assembler_state == SUCCESS) ? 3'b010 : 3'b001; // RED FOR ERROR & GREEN FOR SUCCESS

  logic [$clog2(SCREEN_HEIGHT) - 1 : 0] num_instructions;
  evt_counter #( 
    .MAX_COUNT(SCREEN_HEIGHT)
  ) pc_counter (   
    .clk_in(clk_pixel),
    .rst_in(sys_rst || assembler_trigger),
    .evt_in(assembler_new_inst),
    .count_out(num_instructions)
  );

  logic [$clog2(SCREEN_WIDTH) - 1:0] new_assembler_x;
  assign new_assembler_x = (assembler_x[0] + !assembler_new_char[0]);

  always_ff @(posedge clk_pixel) begin // Handles the assembler state
    if (sys_rst) begin
      assembler_state <= IDLE; // KEEP STUFF OFF
      text_transmission_state <= OFF;
    end else if (assembler_trigger) begin // START THE PROCESS
      assembler_state <= PC_MAPPING;
      assembler_x <= 0;
      assembler_y <= 0;
      text_transmission_state <= START;
      assembler_new_char <= 0;
    end else if (assembler_line_error) assembler_state <= ERROR; // ERROR HANDLING
    else if (assembler_state == PC_MAPPING || assembler_state == INSTRUCTION_MAPPING) begin
      case (text_transmission_state)
        START: text_transmission_state <= NEW_LINE;
        NEW_LINE: text_transmission_state <= SENDING_CHARS; // single high pulse
        SENDING_CHARS: begin // SENDING CHARACTERS
            if (assembler_x[2] == SCREEN_WIDTH - 1 || assembler_line_done) begin // end of the line
              if (assembler_y == SCREEN_HEIGHT - 1) begin // LAST LINE
                if (assembler_state == PC_MAPPING) begin // another go around
                  assembler_state <= INSTRUCTION_MAPPING;
                  assembler_y <= 0;
                  text_transmission_state <= START;
                end else begin // Ending protocol
                  assembler_state <= SUCCESS; 
                  text_transmission_state <= OFF;
                end
              end else begin // NEW LINE
                text_transmission_state <= NEW_LINE;
                assembler_y <= assembler_y + 1; // Increment the line count
              end

              assembler_x <= 0; // Reset the char count
              assembler_new_char <= 0; // Reset the sending of chars

            end else begin // ACTIVELY SENDING CHARACTERS
              assembler_x <= {assembler_x[1:0], new_assembler_x};
              assembler_new_char <= {assembler_new_char[1:0], !assembler_new_char[0]};
            end
        end
      endcase

    end

  end

  assembler #(
    .CHAR_PER_LINE(SCREEN_WIDTH),
    .NUMBER_LINES(SCREEN_HEIGHT),
    .NUM_LABELS(8),
    .LABEL_SIZE(6)
  ) _assembler (     
    .clk_in(clk_pixel),
    .rst_in(sys_rst || assembler_trigger), // wait until the button is not pressed to start
    .new_line(assembler_new_line), 
    .new_character(assembler_new_char[2]),
    .line_count(assembler_y),
    .char_count(assembler_x[2]),
    .incoming_character(text_editor_output), // Each new character 
    .done_flag(assembler_line_done), // Instruction is Ready
    .error_flag(assembler_line_error), // Error encountered
    .assembler_state(assembler_state), // Determines what we are doing at any given point
    .instruction(new_instruction),
    .new_instruction(assembler_new_inst)
);  

    xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(SCREEN_HEIGHT*SCREEN_WIDTH),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) text_editor (
    .addra(terminal_grid_addr),   // Writes (terminal)
    .addrb(text_editor_addr),   // Reads (assembler)
    .dina(terminal_grid_input),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_pixel),     // clock
    .wea(terminal_grid_write_enable),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb((assembler_state == PC_MAPPING || assembler_state == INSTRUCTION_MAPPING)),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),     // Port A output reset (does not affect memory contents)
    .rstb(sys_rst || assembler_trigger),     // Port B output reset (does not affect memory contents)
    .regcea(1'b0), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(text_editor_output)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  // End of assmbler and text editor code
  // ****************************************
  
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