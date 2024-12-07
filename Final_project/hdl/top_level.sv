`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
    output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
   // camera bus
   );
logic [31:0] val_to_display; //either the spi data or the btn_count data (default)


  //initialize 
logic [6:0] ss_c; //used to grab output cathode signal for 7s leds
logic [3:0] ss_a; //used to grab output anode signal for 7s leds
logic ss0_c




   // a handful of debug signals for writing to registers
   assign led[0] = crw.bus_active;
   assign led[1] = cr_init_valid;
   assign led[2] = cr_init_ready;
   assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire

