`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module character_sprites #(
  parameter WIDTH=20, HEIGHT=471, NUM_CHARS=26) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [15:0] character_select,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  input wire [39:0][63:0] terminal_grid,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  /*always_comb begin
    for (int i = 0; i < $size(terminal_grid); i++) begin
      for (int j = 0; j < $size(terminal_grid[i]); j++) begin
        if (terminal_grid[i][j]) begin
          
        end
      end
    end
  end*/

  logic [NUM_CHARS-1:0][23:0] output_colors;
  genvar i;

  generate   
    for (i = 0; i < NUM_CHARS; i++) begin
      // calculate rom address
      logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
      logic in_sprite;
      logic [NUM_CHARS-1:0][7:0] pallete_addr;

      assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH) + (i*360);
      assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) && (vcount_in >= y_in && vcount_in < (y_in + 18))) ||
                     ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) && (vcount_in >= y_in+18 && vcount_in < (y_in+18 + 18)));

      character_image #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(65536),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(image.mem))
      ) ci (
        .addra(image_addr),
        .dina(0),
        .clka(pixel_clk_in),
        .wea(0),
        .ena(1),
        .rsta(rst_in),
        .regcea(1),
        .douta(pallete_addr[i])
      );

      character_pallete #(
        .RAM_WIDTH(24),                       // Specify RAM data width
        .RAM_DEPTH(256),                      // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(palette.mem))       // Specify name/location of RAM initialization file if using one (leave blank if not)
      ) cp (
        .addra(pallete_addr[i]),              // Address bus, width determined from RAM_DEPTH
        .dina(0),                             // RAM input data, width determined from RAM_WIDTH
        .clka(pixel_clk_in),                  // Clock
        .wea(0),                              // Write enable
        .ena(1),                              // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),                        // Output reset (does not affect memory contents)
        .regcea(1),                           // Output register enable
        .douta(output_colors[i])              // RAM output data, width determined from RAM_WIDTH
      );
    end
  endgenerate

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
