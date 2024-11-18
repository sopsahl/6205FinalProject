`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic in_sprite;
  assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                      (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));

  logic [23:0] output_colors;
  logic [7:0] pallete_addr;

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? output_colors[23:16] : 0;
  assign green_out =  in_sprite ? output_colors[15:8] : 0;
  assign blue_out =   in_sprite ? output_colors[7:0] : 0;
  
  //  Xilinx Single Port Read First RAM (image)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_image (
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
  ) popcat_pallete (
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

module alphabet_sprite #(
  parameter WIDTH=20, HEIGHT=471) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [15:0] character,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) + (character*360);

  logic in_sprite;
  assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
                      (vcount_in >= y_in && vcount_in < (y_in + 18)));

  logic [23:0] output_colors;
  logic [7:0] pallete_addr;

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? output_colors[23:16] : 0;
  assign green_out =  in_sprite ? output_colors[15:8] : 0;
  assign blue_out =   in_sprite ? output_colors[7:0] : 0;
  
  //  Xilinx Single Port Read First RAM (image)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_image (
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
  ) popcat_pallete (
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

module image_sprite_2 #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  input wire pop_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

	//ps10
	logic [10:0] hcountpipe [3:0];
	logic [10:0] vcountpipe [3:0];

	always_ff @(posedge pixel_clk_in)begin
	  hcountpipe[0] <= hcount_in;
	  vcountpipe[0] <= vcount_in;
	  
	  for (int i=1; i<4; i = i+1)begin
		hcountpipe[i] <= hcountpipe[i-1];
		vcountpipe[i] <= vcountpipe[i-1];
	  end
	end

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = pop_in ? (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) : (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) + 65536;

  logic in_sprite;
  assign in_sprite = ((hcountpipe[3] >= x_in && hcountpipe[3] < (x_in + WIDTH)) &&
                      (vcountpipe[3] >= y_in && vcountpipe[3] < (y_in + HEIGHT/2)));

  logic [23:0] output_colors;
  logic [7:0] pallete_addr;

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? output_colors[23:16] : 0;
  assign green_out =  in_sprite ? output_colors[15:8] : 0;
  assign blue_out =   in_sprite ? output_colors[7:0] : 0;
  
  //  Xilinx Single Port Read First RAM (image)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(131072),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_image (
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
    .INIT_FILE(`FPATH(palette2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_pallete (
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
