`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module character_sprites #(
  parameter SIZE=16, HEIGHT=512, SCREEN_WIDTH=76, SCREEN_HEIGHT=44) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire tg_write_en,
  input wire [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] tg_addr,
  input wire [7:0] tg_input,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(SIZE*HEIGHT)-1:0] image_addr;
  logic [12:0] rw_addr;
  logic [7:0] tg_output;
  logic [7:0] ascii2char;
  logic [$clog2(SCREEN_WIDTH)-1:0] x_pos;
  logic [$clog2(SCREEN_WIDTH)-1:0] x_np;
  logic [$clog2(SCREEN_HEIGHT)-1:0] y_pos;
  logic [$clog2(SCREEN_HEIGHT)-1:0] y_np;
  logic [1:0][10:0] h;
  logic [1:0][9:0] v;
//        terminal_grid[y*76+x] <= 0;

  always_comb begin
    case (tg_output)
      32: ascii2char = 0;
      97: ascii2char = 1;
      98: ascii2char = 2;
      99: ascii2char = 3;
      100: ascii2char = 4;
      101: ascii2char = 5;
      102: ascii2char = 6;
      103: ascii2char = 7;
      104: ascii2char = 8;
      105: ascii2char = 9;
      106: ascii2char = 10;
      107: ascii2char = 11;
      108: ascii2char = 12;
      109: ascii2char = 13;
      110: ascii2char = 14;
      111: ascii2char = 15;
      112: ascii2char = 16;
      113: ascii2char = 17;
      114: ascii2char = 18;
      115: ascii2char = 19;
      116: ascii2char = 20;
      117: ascii2char = 21;
      118: ascii2char = 22;
      119: ascii2char = 23;
      120: ascii2char = 24;
      121: ascii2char = 25;
      122: ascii2char = 26;
      60: ascii2char = 27;
      62: ascii2char = 28;
      40: ascii2char = 29;
      41: ascii2char = 30;
      61: ascii2char = 31;
      default: ascii2char = 0;
    endcase
  end

  assign x_pos = (h[1]>>4) < SCREEN_WIDTH ? (h[1]>>4) : SCREEN_WIDTH - 1;
  assign y_pos = (v[1]>>4) < SCREEN_HEIGHT ? (v[1]>>4) : SCREEN_HEIGHT - 1;

  assign x_np = (hcount_in>>4) < SCREEN_WIDTH ? (hcount_in>>4) : SCREEN_WIDTH - 1;
  assign y_np = (vcount_in>>4) < SCREEN_HEIGHT ? (vcount_in>>4) : SCREEN_HEIGHT - 1;

  assign rw_addr = tg_write_en ? tg_addr : y_np * SCREEN_WIDTH + x_np;
  assign image_addr = (h[1] - 16*x_pos) + ((v[1] - 16*y_pos) * SIZE) + (ascii2char*SIZE*SIZE);

  logic [5:0] in_sprite;
  logic [23:0] output_colors;
  logic [7:0] pallete_addr;

  always_ff @(posedge pixel_clk_in) begin
    if (rst_in) begin
      in_sprite <= 0;
      h <= 0;
      v <= 0;
    end else begin
      h[0] <= hcount_in;
      h[1] <= h[0];

      v[0] <= vcount_in;
      v[1] <= v[0];

      in_sprite[0] <= ((hcount_in >= 16*x_np && hcount_in < (16*x_np + SIZE)) && (vcount_in >= 16*y_np && vcount_in < (16*y_np + SIZE)));// && tg_output != 0;
      in_sprite[1] <= in_sprite[0];
      in_sprite[2] <= in_sprite[1];
      in_sprite[3] <= in_sprite[2];
      in_sprite[4] <= in_sprite[3];
      in_sprite[5] <= in_sprite[4];
    end
  end

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite[5] ? output_colors[23:16] : 0;
  assign green_out =  in_sprite[5] ? output_colors[15:8] : 0;
  assign blue_out =   in_sprite[5] ? output_colors[7:0] : 0;

  //  Xilinx Single Port Read First RAM (terminal grid)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width (should be 6 for 26 char but said 8 for ease)
    .RAM_DEPTH(SCREEN_WIDTH*SCREEN_HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(terminal_grid.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) terminal_grid (
    .addra(rw_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(tg_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(tg_write_en),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(tg_output)      // RAM output data, width determined from RAM_WIDTH
  );
  
  //  Xilinx Single Port Read First RAM (image)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) character_image (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH (TODO)
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(pallete_addr)      // RAM output data, width determined from RAM_WIDTH
  );
  
  //  Xilinx Single Port Read First RAM (pallete)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) character_pallete (
    .addra(pallete_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(output_colors)      // RAM output data, width determined from RAM_WIDTH
  );
endmodule

`default_nettype none
