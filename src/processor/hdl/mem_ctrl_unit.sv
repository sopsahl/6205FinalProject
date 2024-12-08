//use
module Mem_ctrl_unit(
    input  logic        clk,
    input  logic        rst,
    input  logic [2:0]  funct3,         // Operation type
    input  logic [1:0] byte_offset,           // Memory address
    input  logic [31:0] rs2_val,     // Data select for store operations
    input  logic [31:0] mem_rdata,      // Data read from memory
    output logic [31:0] read_result,    // Processed read data
    output logic [31:0] mem_wdata,      // Data to write to memory, edited rs2_val
    output logic [3:0]  mem_be          // Byte enables)
);
 // logic [31:0] load_result;
    // logic [31:0] store_data;
    // logic [3:0] memory_store_enable;
    // logic [31:0] final_store_data;
    // Load operations
    logic [31:0] load_result;
    // logic [1:0] byte_offset;
    // logic [31:0] aligned_addr;
    logic is_unsigned;

    // Extract byte offset and aligned address
    // assign byte_offset = alu_result[1:0];
    // assign aligned_addr = {alu_result[31:2], 2'b00};
    assign is_unsigned = funct3[2];
    // Load operation implementation
    logic [31:0] load_value;
    assign load_value = mem_rdata;
    always_comb begin
    case (funct3[1:0])
        2'b00: begin // Load Byte (lb/lbu)
            case (byte_offset)
                2'b00: load_result = is_unsigned ? {24'b0, mem_rdata[7:0]} :
                                                 {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                2'b01: load_result = is_unsigned ? {24'b0, mem_rdata[15:8]} :
                                                 {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                2'b10: load_result = is_unsigned ? {24'b0, mem_rdata[23:16]} :
                                                 {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                2'b11: load_result = is_unsigned ? {24'b0, mem_rdata[31:24]} :
                                                 {{24{mem_rdata[31]}}, mem_rdata[31:24]};
            endcase
        end

        2'b01: begin // Load Halfword (lh/lhu)
            case (byte_offset[1])
                1'b0: load_result = is_unsigned ? {16'b0, mem_rdata[15:0]} :
                                                {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                1'b1: load_result = is_unsigned ? {16'b0, mem_rdata[31:16]} :
                                                {{16{mem_rdata[31]}}, mem_rdata[31:16]};
            endcase
        end

        2'b10: begin // Load Word (lw)
            load_result = mem_rdata;
        end

        default: load_result = 32'b0;
    endcase
    end
    // Store operations
logic [3:0] store_mask;
// logic [31:0] store_data;
logic [31:0] final_store_data;
// logic [1:0] store_offset;
// logic [31:0] store_addr;


// assign store_offset = alu_result[1:0];//lol lazy programming I guess 
// assign store_addr = {alu_result[31:2], 2'b00};

// Generate store data and mask
always_comb begin
    store_mask = 4'b0000;
    // store_data = rs2_val;
    // final_store_data = dmem[store_addr];

   case (funct3[1:0])
    2'b00: begin // Store Byte (sb)
        case (byte_offset)
            2'b00: begin 
                store_mask = 4'b0001;
                final_store_data = {24'b0, rs2_val[7:0]};
            end
            2'b01: begin
                store_mask = 4'b0010;
                final_store_data = {16'b0, rs2_val[7:0], 8'b0};
            end
            2'b10: begin
                store_mask = 4'b0100;
                final_store_data = {8'b0, rs2_val[7:0], 16'b0};
            end
            2'b11: begin
                store_mask = 4'b1000;
                final_store_data = {rs2_val[7:0], 24'b0};
            end
        endcase
    end

    2'b01: begin // Store Halfword (sh)
        case (byte_offset[1])
            1'b0: begin
                store_mask = 4'b0011;
                final_store_data = {16'b0, rs2_val[15:0]};
            end
            1'b1: begin
                store_mask = 4'b1100;
                final_store_data = {rs2_val[15:0], 16'b0};
            end
        endcase
    end

    2'b10: begin // Store Word (sw)
        store_mask = 4'b1111;
        final_store_data = rs2_val;
    end

    default: begin
        store_mask = 4'b0000;
        final_store_data = 32'b0;
    end
endcase

end
assign mem_wdata = final_store_data;
assign mem_be = store_mask;
assign read_result = load_result;
endmodule
