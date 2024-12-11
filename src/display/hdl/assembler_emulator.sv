`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */
 module assembler_emulator(
    input wire  clk,
    input wire rst,
    output logic data_valid,
    output logic [31:0] data,
    output   logic [31:0]  data_address,
    output logic done_transmitting
 );
 logic[2:0][5:0]instruction_counter;
logic[31:0]instruction_to_send; 
logic [2:0] instruction_valid;
logic instantiate_counter;
logic translation_done;
localparam MAX_INSTRUCTIONS=28;
// logic[5:0] ic1,ic2,ic3;
always_ff@(posedge clk) begin 
    if(rst||!instantiate_counter)begin 
        instruction_counter<=0;
        instantiate_counter=1;
        instruction_valid<=1;
    end
    else begin 
        if(!translation_done)begin 
            instruction_valid<={instruction_valid[1:0],(instruction_counter[0] <= MAX_INSTRUCTIONS-1)};
            instruction_counter<={instruction_counter[1:0],instruction_counter[0]+6'b1};

        end
    end 
end
// assign ic1 = instruction_counter[0];
// assign ic2 = instruction_counter[1];
// assign ic3 = instruction_counter[2];
assign translation_done=(instruction_counter[2]==MAX_INSTRUCTIONS);
 xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(64),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(instructionMem.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)`FPATH(instructionMem.mem)
 ) bro (
    .addra(instruction_counter[0]),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(0),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(instruction_to_send)      // RAM output data, width determined from RAM_WIDTH
  );
    assign data_valid=instruction_valid[2];
    assign data_address=instruction_counter[2];
    assign done_transmitting=translation_done;
    assign data=instruction_to_send;

 endmodule
 `default_nettype wire