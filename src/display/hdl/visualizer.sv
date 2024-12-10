`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module visualizer #(
  parameter SIZE=16, HEIGHT=1024, SCREEN_WIDTH=76, SCREEN_HEIGHT=42) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire tg_write_en,
  input wire tg_proc_clk,
  input wire [$clog2(SCREEN_HEIGHT)-1:0] tg_addr,
  input wire [31:0] tg_input,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(SIZE*HEIGHT)-1:0] image_addr;
  logic [$clog2(SCREEN_HEIGHT)-1:0] read_addr;
  logic [31:0] tg_output;
  logic [31:0] bar_height;
  logic [$clog2(SCREEN_WIDTH)-1:0] x_pos;
  logic [$clog2(SCREEN_WIDTH)-1:0] x_np;
  logic [$clog2(SCREEN_HEIGHT)-1:0] y_pos;
  logic [$clog2(SCREEN_HEIGHT)-1:0] y_np;
  logic [1:0][10:0] h;
  logic [1:0][9:0] v;
//        terminal_grid[y*76+x] <= 0;

  assign x_pos = (h[1]>>4) < SCREEN_WIDTH ? (h[1]>>4) : SCREEN_WIDTH - 1;
  assign y_pos = (v[1]>>4) < SCREEN_HEIGHT ? (v[1]>>4) : SCREEN_HEIGHT - 1;

  assign x_np = (hcount_in>>4) < SCREEN_WIDTH ? (hcount_in>>4) : SCREEN_WIDTH - 1;
  assign y_np = (vcount_in>>4) < SCREEN_HEIGHT ? (vcount_in>>4) : SCREEN_HEIGHT - 1;

  assign image_addr = (h[1] - 16*x_pos) + ((v[1] - 16*y_pos) * SIZE) + (34*SIZE*SIZE); // ascii2char --> 34 (hashtag only)

  logic [5:0] in_sprite;
  logic [23:0] output_colors;
  logic [7:0] pallete_addr;
  logic [$clog2(SIZE)-1:0] counter; // counter to decrement bar height

  always_ff @(posedge pixel_clk_in) begin
    if (rst_in) begin
      in_sprite <= 0;
      read_addr <= 0;
      h <= 0;
      v <= 0;
      counter <= 0;
    end else begin
      h[0] <= hcount_in;
      h[1] <= h[0];

      v[0] <= vcount_in;
      v[1] <= v[0];

      in_sprite[0] <= ((hcount_in >= 16*x_np && hcount_in < (16*x_np + SIZE)) && (vcount_in >= 16*y_np && vcount_in < (16*y_np + SIZE))) && bar_height > 0; // dont show hashtag if bar_height is zero
      in_sprite[1] <= in_sprite[0];
      in_sprite[2] <= in_sprite[1];
      in_sprite[3] <= in_sprite[2];
      in_sprite[4] <= in_sprite[3];
      in_sprite[5] <= in_sprite[4];

      counter <= counter + 1; // counter loops from 0 to 15

      if (hcount_in == 0) begin   
        read_addr <= vcount_in>>4;

        if (tg_output > 0) begin     
            bar_height <= tg_output * SIZE - 2;
        end else begin
            bar_height <= 0;
        end
      end else begin
        if (bar_height > 0) begin
            bar_height <= bar_height - 1;
        end
      end
    end
  end

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite[5] ? output_colors[23:16] : 0;
  assign green_out =  in_sprite[5] ? output_colors[15:8] : 0;
  assign blue_out =   in_sprite[5] ? output_colors[7:0] : 0;
  //DUAL port ? 
  //  Xilinx Single Port Read First RAM (register values)
  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(32),                       // Specify RAM data width (should be 6 for 26 char but said 8 for ease)
  //   .RAM_DEPTH(SCREEN_HEIGHT),                     // Specify RAM depth (number of entries)
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  //   //changed to dataMem.mem to start out 
  //   .INIT_FILE(`FPATH(dataMem.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  // ) register_values (
  //   .addra(tg_write_en ? tg_addr : read_addr),     // Address bus, width determined from RAM_DEPTH
  //   .dina(tg_input),       // RAM input data, width determined from RAM_WIDTH
  //   .clka(pixel_clk_in),       // Clock
  //   .wea(tg_write_en),         // Write enable
  //   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
  //   .rsta(rst_in),       // Output reset (does not affect memory contents)
  //   .regcea(1),   // Output register enable
  //   .douta(tg_output)      // RAM output data, width determined from RAM_WIDTH
  // );
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(SCREEN_HEIGHT),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(dataMem.mem))
  ) register_values (
    // Port A - Read port
    .clka(pixel_clk_in),
    .ena(1),
    .wea(0),
    .addra(read_addr),
    .dina(),
    .douta(tg_output),
    .rsta(rst_in),
    .regcea(1),
    
    // Port B - Write port
    .clkb(tg_proc_clk),
    .enb(1),
    .web(tg_write_en),
    .addrb(tg_addr),
    .dinb(tg_input),
    .doutb(0),
    .rstb(rst_in),
    .regceb(1)
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
