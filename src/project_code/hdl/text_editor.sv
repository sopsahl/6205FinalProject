`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module text_editor #(
  parameter SIZE=16, HEIGHT=1024, SCREEN_WIDTH=76, SCREEN_HEIGHT=42) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire te_write_en,
  input wire [$clog2(SCREEN_WIDTH*SCREEN_HEIGHT)-1:0] te_addr,
  input wire [7:0] te_input,
  output logic [7:0] te_output
  );

  //  Xilinx Single Port Read First RAM (terminal grid)
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width (should be 6 for 26 char but said 8 for ease)
    .RAM_DEPTH(SCREEN_WIDTH*SCREEN_HEIGHT),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(terminal_grid.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) text_editor_bram (
    .addra(te_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(te_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(te_write_en),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(te_output)      // RAM output data, width determined from RAM_WIDTH
  );
endmodule

`default_nettype none
