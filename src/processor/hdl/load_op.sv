// Load operations
logic [31:0] load_result;
logic [1:0] byte_offset;
logic [31:0] aligned_addr;
logic is_unsigned;

// Extract byte offset and aligned address
assign byte_offset = alu_result[1:0];
assign aligned_addr = {alu_result[31:2], 2'b00};
assign is_unsigned = inst_fields.funct3[2];

// Load operation implementation
always_comb begin
    case (inst_fields.funct3[1:0])
        2'b00: begin // Load Byte (lb/lbu)
            case (byte_offset)
                2'b00: load_result = is_unsigned ? {24'b0, dmem[aligned_addr][7:0]} :
                                                 {{24{dmem[aligned_addr][7]}}, dmem[aligned_addr][7:0]};
                2'b01: load_result = is_unsigned ? {24'b0, dmem[aligned_addr][15:8]} :
                                                 {{24{dmem[aligned_addr][15]}}, dmem[aligned_addr][15:8]};
                2'b10: load_result = is_unsigned ? {24'b0, dmem[aligned_addr][23:16]} :
                                                 {{24{dmem[aligned_addr][23]}}, dmem[aligned_addr][23:16]};
                2'b11: load_result = is_unsigned ? {24'b0, dmem[aligned_addr][31:24]} :
                                                 {{24{dmem[aligned_addr][31]}}, dmem[aligned_addr][31:24]};
            endcase
        end

        2'b01: begin // Load Halfword (lh/lhu)
            case (byte_offset[1])
                1'b0: load_result = is_unsigned ? {16'b0, dmem[aligned_addr][15:0]} :
                                                {{16{dmem[aligned_addr][15]}}, dmem[aligned_addr][15:0]};
                1'b1: load_result = is_unsigned ? {16'b0, dmem[aligned_addr][31:16]} :
                                                {{16{dmem[aligned_addr][31]}}, dmem[aligned_addr][31:16]};
            endcase
        end

        2'b10: begin // Load Word (lw)
            load_result = dmem[aligned_addr];
        end

        default: load_result = 32'b0;
    endcase
end

// Write back loaded value to register
always_ff @(posedge clk) begin
    if (!rst && mem_read) begin
        registers[inst_fields.rd] <= load_result;
    end
end