`timescale 1ns / 1ps
`default_nettype none

import constants::*;

module assembler_test #(
    parameter SCREEN_HEIGHT = 64,
    parameter SCREEN_WIDTH = 64
)(
    input wire clk_pixel,
    input wire sys_rst,
    input wire [15:0] sw,

    output logic [31:0] new_instruction,
    output logic assembler_new_inst,
    output logic [5:0] num_instructions
);
// *************************************************
  // ASSEMBLY AND TEXT EDITOR

  logic [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] text_editor_addr;
  logic [7:0] text_editor_output;

  // logic assembler_trigger;
  // debouncer #(
  //   .CLK_PERIOD_NS(10),
  //   .DEBOUNCE_TIME_MS(5))
  // assembler_trig (
  //   .clk_in(clk_pixel),
  //   .rst_in(sys_rst),
  //   .dirty_in(btn[1]),
  //   .clean_out(assembler_trigger));

//   logic [6:0] ss_c;
//   seven_segment_controller sg (
//     .clk_in(clk_pixel),
//     .rst_in(sys_rst),
//     .val_in(assembler_state),
//     .cat_out(ss_c),
//     .an_out({ss0_an, ss1_an}));

  logic assembler_trigger, assembler_trigger_buffer;
  assign assembler_trigger = sw[1];

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

  logic assembler_line_done, assembler_line_error;
//   logic [31:0] new_instruction;

  assign text_editor_addr =  (assembler_y * SCREEN_WIDTH) + assembler_x[0]; // locates the point in memory
//   assign rgb1 = (assembler_state == ERROR) ? 3'b100 : (assembler_state == SUCCESS) ? 3'b010 : 3'b001; // RED FOR ERROR & GREEN FOR SUCCESS

//   logic [$clog2(SCREEN_HEIGHT) - 1 : 0] num_instructions;
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
        NEW_LINE: begin 
          text_transmission_state <= SENDING_CHARS; // single high pulse
          assembler_new_char <= 3'b001;
        end SENDING_CHARS: begin // SENDING CHARACTERS
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
    .INIT_FILE("/Users/ziyadhassan/6205/6205FinalProject/src/final_build/sim/bubbleSort.mem")                  // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) text_editor (
    .addra(),   // Writes (terminal)
    .addrb(text_editor_addr),   // Reads (assembler)
    .dina(),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_pixel),     // clock
    .wea(1'b0),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),     // Port A output reset (does not affect memory contents)
    .rstb(sys_rst || assembler_trigger),     // Port B output reset (does not affect memory contents)
    .regcea(1'b0), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(text_editor_output)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  // End of assmbler and text editor code
  // ****************************************

endmodule


`default_nettype wire