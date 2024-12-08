`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
  //   output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  // output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  // output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  // output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
   // camera bus
// seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c //cathod controls for the segments of lower four digits
    );
// logic [31:0] val_to_display; //either the spi data or the btn_count data (default)
logic rst;
logic [31:0] ending_pc;
logic [31:0] pc_out;
logic instruction_done;
assign ending_pc = 224;
logic done_rest;
always_ff@(posedge clk_100mhz)begin
  if(!done_rest)begin
    done_rest <= 1;
    rst<=1;

  end
  if(done_rest)begin
    rst<=0;
  end
end
logic [6:0] ss_c; //used to grab output cathode signal for 7s leds

riscv_processor pr (
  .clk(clk_100mhz),
  .rst(rst),
  .ending_pc(ending_pc),
  .pc_out(pc_out),
  .instruction_done(instruction_done)
);
logic [31:0] val_to_display;
assign val_to_display = pc_out;
seven_segment_controller mssc(.clk_in(clk_100mhz),
                               .rst_in(rst),
                               .val_in(val_to_display),
                               .cat_out(ss_c),
                               .an_out({ss0_an, ss1_an}));
assign ss0_c = ss_c; //control upper four digit's cathodes!
assign ss1_c = ss_c; //same as above but for lower four digits!
//   //initialize 
// logic [6:0] ss_c; //used to grab output cathode signal for 7s leds
// logic [3:0] ss_a; //used to grab output anode signal for 7s leds
// logic ss0_c




//    // a handful of debug signals for writing to registers
//    assign led[0] = crw.bus_active;
//    assign led[1] = cr_init_valid;
//    assign led[2] = cr_init_ready;
//    assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire

