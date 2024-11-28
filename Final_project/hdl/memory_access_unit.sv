module memory_access_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] addr_in,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,
    
    // mem interface temporary output probably
    input  logic [31:0] dmem_rdata,
    output logic [31:0] dmem_wdata,
    // output logic [31:0] dmem_addr,
    output logic [3:0]  dmem_we
);

 // Extract byte offset and aligned address
     logic [1:0] byte_offset;
     assign byte_offset = addr_in[1:0];
     logic [31:0] aligned_addr;
     assign aligned_addr = {addr_in[31:2], 2'b00};
     logic is_unsigned;
     assign is_unsigned = funct3[2];
    // Load operation implementation
    // logic [31:0] load_value;
    // assign load_value = dmem_rdata;
    logic [31:0] load_result;
    always_comb begin
    case (funct3[1:0])
        2'b00: begin // Load Byte (lb/lbu)
            case (byte_offset)
                2'b00: load_result = is_unsigned ? {24'b0, dmem_rdata[7:0]} :
                                                 {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                2'b01: load_result = is_unsigned ? {24'b0, dmem_rdata[15:8]} :
                                                 {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                2'b10: load_result = is_unsigned ? {24'b0, dmem_rdata[23:16]} :
                                                 {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                2'b11: load_result = is_unsigned ? {24'b0, dmem_rdata[31:24]} :
                                                 {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
            endcase
        end

        2'b01: begin // Load Halfword (lh/lhu)
            case (byte_offset[1])
                1'b0: load_result = is_unsigned ? {16'b0, dmem_rdata[15:0]} :
                                                {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                1'b1: load_result = is_unsigned ? {16'b0, dmem_rdata[31:16]} :
                                                {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
            endcase
        end

        2'b10: begin // Load Word (lw)
            load_result = dmem_rdata;
        end

        default: load_result = 32'b0;
    endcase
    end
    assign read_data = load_result;
    // Store operations
logic [3:0] store_mask;
logic [31:0] store_data;
logic [31:0] final_store_data;
logic [1:0] store_offset;
logic [31:0] store_addr;

// Extract offset and aligned address for stores
assign store_offset = addr_in[1:0];
assign store_addr = {addr_in[31:2], 2'b00};

// Generate store data and mask. Handle the actual storing outside the module maaaaybe for now 
always_comb  begin
    dmem_we = 4'b0000;
    dmem_wdata = write_data;

    if (mem_write) 
    begin
        case (funct3[1:0])
            2'b00: 
            begin // Byte
                case (byte_offset)
                    2'b00: 
                        begin 
                            dmem_we = 4'b0001; 
                            dmem_wdata = {24'b0, write_data[7:0]}; 
                        end
                    2'b01: 
                        begin 
                            dmem_we = 4'b0010; 
                            dmem_wdata = {16'b0, write_data[7:0], 8'b0}; 
                        end
                    2'b10: 
                        begin 
                            dmem_we = 4'b0100; 
                            dmem_wdata = {8'b0, write_data[7:0], 16'b0}; 
                        end
                    2'b11: 
                        begin 
                            dmem_we = 4'b1000; 
                            dmem_wdata = {write_data[7:0], 24'b0}; 
                        end
                endcase
            end
                
            2'b01: 
            begin // Halfword
                case (byte_offset[1])
                    1'b0: 
                    begin 
                        dmem_we = 4'b0011; 
                        dmem_wdata = {16'b0, write_data[15:0]}; 
                    end
                    1'b1: 
                    begin 
                        dmem_we = 4'b1100; 
                        dmem_wdata = {write_data[15:0], 16'b0}; 
                    end
                endcase
            end
                
            2'b10: 
            begin // Word
                dmem_we = 4'b1111;
                dmem_wdata = write_data;
            end
        endcase
    end
end




endmodule