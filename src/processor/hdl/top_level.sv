`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */
module top_level
  (
   input wire          clk_100mhz,
  //   output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  // output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  // output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  // output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
   // camera bus
// seven segment
input wire[3:0] btn,  //buttons
  output logic [15:0] led,
  output logic [2:0] rgb0,
  output logic [2:0] rgb1,
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c //cathod controls for the segments of lower four digits
    );
// logic [31:0] val_to_display; //either the spi data or the btn_count data (default)
// logic [31:0] btn_count; //used to count the number of times the button is pressed
logic [31:0] processor_address_write;
logic [31:0] processor_write_data;
logic processor_w_enable;
  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(1024),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(dataMem.mem))
  ) dmem_processor (
    // Port A - Read port
    .clka(clk_100mhz),
    .ena(processor_r_enable),
    .wea(1'b0),
    .addra(processor_address_read),
    .dina(),
    .douta(processor_read_data),//should be the load value from 2 cycles later 
    .rsta(rst),
    .regcea(1'b1),
    
    // Port B - Write port
    .enb(processor_w_enable),//last stage
    .web(1'b1),
    .addrb(processor_address_write),
    .dinb(processor_write_data),
    .doutb(),
    .rstb(rst),
    .regceb(1'b1)
);
logic [31:0] processor_address_read;
logic processor_r_enable;
logic [31:0] processor_read_data;

// //read data from bram wait 2 cycles display that for 100000 cycles then display the next value
// logic [31:0] val_to_display;

// logic [$clog2(100_000)-1 :0] count_disp;
// logic initialize_disp;
// always_ff@(posedge clk_100mhz)begin
//   if(!initialize_disp)begin 
//     count_disp<=1;
//     initialize_disp<=1;
//     processor_address_read<=0;
//   end 
//   else begin 
    
//     if(count_disp==100_000-1)begin
//       if(processor_address_read==9)begin 
//         processor_address_read<=0;
//       end 
//       else begin 
//       processor_address_read<=processor_address_read+1;
//       end
//       count_disp<=0;
//     end
//     else begin 
//       count_disp<=count_disp+1;
//     end 

//   end
// end
// logic [31:0] prev_val_to_display;
// always_ff@(posedge clk_100mhz)begin
//   prev_val_to_display<=val_to_display;
// end
// assign processor_r_enable = !count_disp && instruction_done_2;
// assign val_to_display = !btn[1]?{processor_address_read[15:0],processor_read_data[15:0]}:prev_val_to_display;
logic rst;
assign rst = btn[0];
assign rgb1 = 0; 
assign rgb0 = 0;
assign led = 0;
logic [31:0] ending_pc;
logic [31:0] pc_out;
logic instruction_done;
assign ending_pc = 224;
logic done_rest;

logic [6:0] ss_c; //used to grab output cathode signal for 7s leds

riscv_processor pr (
  .clk(clk_100mhz),
  .rst(rst),
  .ending_pc(ending_pc),
  .pc_out(pc_out),
  .instruction_done(instruction_done),
  .write_enable(processor_w_enable),
  .w_data(processor_write_data),
  .w_addr(processor_address_write)
);

// assign val_to_display = pc_out;
logic instruction_done_2;
always_ff@(posedge clk_100mhz)begin
  if(instruction_done)begin
    instruction_done_2<=1;
  end
end
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

