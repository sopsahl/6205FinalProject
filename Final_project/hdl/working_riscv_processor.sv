module riscv_processor_working (
    input  logic        clk,
    input  logic        rst,
  
    output logic [31:0] pc_out
);
    // Program Counter
    logic [31:0] pc;
    assign pc_out = pc;

    // Memory and Registers
    logic [31:0] imem [1023:0];  // Instruction memory
    logic [31:0] dmem [1023:0];  // Data memory

    logic [31:0] registers [31:0];
    logic registers_initialized;
    
    // Instruction Fields
    typedef struct packed {
        logic [6:0] opcode;
        logic [4:0] rd;
        logic [2:0] funct3;
        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [6:0] funct7;
    } InstFields;

    
    InstFields inst_fields;
    logic [31:0] instruction;
    logic [31:0] imm;
    
    // Control Signals
    logic reg_write;
    logic mem_to_reg;
    logic mem_read;
    logic mem_write;
    logic alu_src;
    logic branch;
    logic jump;
    
    // Register values
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] rd_val;
    
    // ALU
    logic [31:0] alu_result;
    logic [3:0] alu_ctrl;

    // Initialize registers at start
   

    always_ff @(posedge clk)begin 
        if(rst)begin 
            registers_initialized<=1'b0;
            pc<=32'b0;
        end else if (!registers_initialized) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
            for(int i=0;i<1024;i++)begin
                imem[i]<=32'b0;
                dmem[i]<=32'b0;
            end
            registers_initialized <= 1'b1;
            

        end
        else begin 
        
            if(jump && alu_src)//jalr
                pc <= alu_result;
            else if (jump )//jal
                pc <= pc + imm;
            else if (branch && branch_taken)
                pc <= pc + imm;
       
            else
                pc <= pc + 4;  // Increment by 1 instead of 4

        end


    end
    // always_comb begin
    //    imem[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
    //     imem[4] = 32'h00A00113; // addi x2, x0, 10
    //     imem[8] = 32'b00000000001000001000000110110011; // add x3, x1, x2
    //     imem[12] = 32'h0140006F;; // jal x1,  (jump to line 8)
    //     imem[32] = 32'h00218223; // sw x3, 4(x1)
    //     imem[36]= 32'b0100000_00010_00011_000_11111_0110011;//SUB x31,x3,x2
    //     imem[40] = 32'b0100000_00010_11111_000_11110_0110011;//xor x30,x31,x2
    //     imem[44]= 32'b0000000_00011_00000_000_11101_0110011;//or x29,x3,x0




    


    //     // imem[1]=32'hA00113;
    //     // imem[2]=32'h2081B3;
        
    // end
    // Instruction fetch
    assign instruction = imem[pc];
    
    // Instruction decode
    always_comb begin
        inst_fields.opcode = instruction[6:0];
        inst_fields.rd     = instruction[11:7];
        inst_fields.funct3 = instruction[14:12];
        inst_fields.rs1    = instruction[19:15];
        inst_fields.rs2    = instruction[24:20];
        inst_fields.funct7 = instruction[31:25];
    end

    logic lui_enable;
    // Immediate generation
    logic [6:0] opcode; 
    assign opcode=inst_fields.opcode;
    // always_comb begin
    //     case (inst_fields.opcode)
    //         7'b0010011, 7'b0000011, 7'b1100111: // I-type
    //             imm = {{20{instruction[31]}}, instruction[31:20]};
    //         7'b0100011: // S-type
    //             imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    //         7'b1100011: // B-type
    //             imm = {{19{instruction[31]}}, instruction[31], instruction[7], 
    //                   instruction[30:25], instruction[11:8], 1'b0};
    //         7'b0110111, 7'b0010111: // U-type
    //             imm = {instruction[31:12], 12'b0};
    //         7'b1101111: // J-type
    //             imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
    //                   instruction[20], instruction[30:21], 1'b0};
    //         default: imm = 32'b0;
    //     endcase
    // end
    // logic [6:0] opcode;
    always_comb begin 
        imm = generate_imm(instruction,inst_fields.opcode);

    end

    // Register read
    assign rs1_val = registers[inst_fields.rs1];
    assign rs2_val = (inst_fields.opcode == 7'b0010011) ? imm :registers[inst_fields.rs2];

    // Control logic
    // always_comb begin
    //     reg_write = 1'b0;
    //     mem_to_reg = 1'b0;
    //     mem_read = 1'b0;
    //     mem_write = 1'b0;
    //     branch = 1'b0;
    //     alu_src = 1'b0;
    //     jump = 1'b0;

    //     case (inst_fields.opcode)
    //         7'b0110011: begin // R-type
    //             reg_write = 1'b1;
    //         end
    //         7'b0010011: begin // I-type ALU
    //             reg_write = 1'b1;
    //             alu_src = 1'b1;
    //         end
    //         7'b0000011: begin // LOAD
    //             reg_write = 1'b1;
    //             alu_src = 1'b1;
    //             mem_to_reg = 1'b1;
    //             mem_read = 1'b1;
    //         end
    //         7'b0100011: begin // STORE
    //             mem_write = 1'b1;
    //             alu_src = 1'b1;
    //         end
    //         7'b1100011: begin // BRANCH
    //             branch = 1'b1;
    //         end
    //         7'b1101111: begin // JAL
    //             reg_write = 1'b1;
    //             jump = 1'b1;
    //         end
    //         7'b1100111: begin // JALR
    //             reg_write = 1'b1;
    //             jump = 1'b1;
    //             alu_src = 1'b1;
    //         end
    //         7'b0110111: begin // LUI
    //             reg_write = 1'b1;
    //             // alu_src = 1'b1;    // Use immediate
    //             // alu_ctrl = 4'b1010; // New ALU op for LUI
    //             // lui_enable = 1'b1;
               
    //     end
    //     7'b0010111: begin // AUIPC
    //         reg_write = 1'b1;
    //         // alu_src = 1'b1;    // Use immediate
    //         // alu_ctrl = 4'b1011; // New ALU op for AUIPC
    //     end 
    //     endcase
    // end
    // logic [2:0] function3;
    // assign function3=inst_fields.funct3;
    // // ALU control
    // always_comb begin
    //     case (inst_fields.opcode)
    //         7'b0110011: begin // R-type,
    //             case (inst_fields.funct3)
    //                 3'b000: alu_ctrl = (inst_fields.funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
    //                 3'b100: alu_ctrl = 4'b0100; // XOR
    //                 3'b110: alu_ctrl = 4'b0011; // OR
    //                 3'b111: alu_ctrl = 4'b0010; // AND
    //                 3'b001: alu_ctrl = 4'b0101; //sll
    //                 3'b101: alu_ctrl = inst_fields.funct7[5] ? 4'b0111 : 4'b0110; //sra(funct7:2):srl
    //                 3'b010: alu_ctrl = 4'b1000; //slt
    //                 3'b011: alu_ctrl = 4'b1001; //sltu
                   

    //                 default: alu_ctrl = 4'b0000;
    //             endcase
    //         end
    //         7'b0010011: begin // I-type ALU
    //             case (inst_fields.funct3)
    //                 3'b000: alu_ctrl = 4'b0000; // ADD
    //                 3'b100: alu_ctrl = 4'b0100; // XOR
    //                 3'b110: alu_ctrl = 4'b0011; // OR
    //                 3'b111: alu_ctrl = 4'b0010; // AND
    //                 3'b001: alu_ctrl = 4'b0101; // SLL
    //                 3'b101: alu_ctrl = imm[5] ? 4'b0111 : 4'b0110; //sra(funct7:2):srl //SOOO the thing is this is just based on imm 11:5 and the rest is 4:0
    //                 3'b010: alu_ctrl = 4'b1000; // SLT
    //                 3'b011: alu_ctrl = 4'b1001; // SLTU
    //                 default: alu_ctrl = 4'b0000;
    //             endcase
    //         end
    //         7'b0010111: begin // AUIPC
    //             alu_ctrl = 4'b1011; // New ALU op for AUIPC
    //         end
    //         7'b0110111: begin // LUI
    //             alu_ctrl = 4'b1010; // New ALU op for LUI
    //         end


    //         default: begin end 
    //     endcase
    // end
    control_unit ctrl(
        .opcode(inst_fields.opcode),
        .funct3(inst_fields.funct3),
        .funct7(inst_fields.funct7),
        .reg_write(reg_write),
        .imm(imm),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl)
    );
    // ALU

    always_comb begin
        case (alu_ctrl)
            4'b0000: alu_result = rs1_val + (alu_src ? imm : rs2_val); // ADD
            4'b0001: alu_result = rs1_val - rs2_val; // SUB
            4'b0010: alu_result = rs1_val & rs2_val; // AND
            4'b0011: alu_result = rs1_val | rs2_val; // OR
            4'b0100: alu_result = rs1_val ^ rs2_val; // XOR
            4'b0101: alu_result = rs1_val << rs2_val[4:0]; // SLL
            4'b0110: alu_result = rs1_val >> rs2_val[4:0]; // SRL
            4'b0111: alu_result = $signed(rs1_val) >>> rs2_val[4:0]; // SRA
            4'b1000: alu_result = $signed(rs1_val) < $signed(rs2_val) ? 32'd1 : 32'd0; // SLT
            4'b1001: alu_result = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
            4'b1010: alu_result = imm; // LUI
            4'b1011: alu_result = pc + imm;             // AUIPC

            default: alu_result = rs1_val + (alu_src ? imm : rs2_val);
        endcase
    end
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
    logic [31:0] load_value;
    assign load_value = dmem[aligned_addr];
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
    // Store operations
logic [3:0] store_mask;
logic [31:0] store_data;
logic [31:0] final_store_data;
logic [1:0] store_offset;
logic [31:0] store_addr;

// Extract offset and aligned address for stores
assign store_offset = alu_result[1:0];
assign store_addr = {alu_result[31:2], 2'b00};

// Generate store data and mask
always_comb begin
    store_mask = 4'b0000;
    store_data = rs2_val;
    final_store_data = dmem[store_addr];

    case (inst_fields.funct3[1:0])
        2'b00: begin // Store Byte (sb)
            case (store_offset)
                2'b00: begin 
                    store_mask = 4'b0001;
                    final_store_data = {dmem[store_addr][31:8], rs2_val[7:0]};
                end
                2'b01: begin
                    store_mask = 4'b0010;
                    final_store_data = {dmem[store_addr][31:16], rs2_val[7:0], dmem[store_addr][7:0]};
                end
                2'b10: begin
                    store_mask = 4'b0100;
                    final_store_data = {dmem[store_addr][31:24], rs2_val[7:0], dmem[store_addr][15:0]};
                end
                2'b11: begin
                    store_mask = 4'b1000;
                    final_store_data = {rs2_val[7:0], dmem[store_addr][23:0]};
                end
            endcase
        end

        2'b01: begin // Store Halfword (sh)
            case (store_offset[1])
                1'b0: begin
                    store_mask = 4'b0011;
                    final_store_data = {dmem[store_addr][31:16], rs2_val[15:0]};
                end
                1'b1: begin
                    store_mask = 4'b1100;
                    final_store_data = {rs2_val[15:0], dmem[store_addr][15:0]};
                end
            endcase
        end

        2'b10: begin // Store Word (sw)
            store_mask = 4'b1111;
            final_store_data = rs2_val;
        end

        default: begin
            store_mask = 4'b0000;
            final_store_data = dmem[store_addr];
        end
    endcase
end

// Write to memory
always_ff @(posedge clk) begin
    if (!rst && mem_write) begin
        if (store_mask[0]) dmem[store_addr][7:0] <= final_store_data[7:0];
        if (store_mask[1]) dmem[store_addr][15:8] <= final_store_data[15:8];
        if (store_mask[2]) dmem[store_addr][23:16] <= final_store_data[23:16];
        if (store_mask[3]) dmem[store_addr][31:24] <= final_store_data[31:24];
    end
end

    // Memory operations
    // always_ff @(posedge clk) begin
    //     if (mem_write)
    //         dmem[alu_result] <= rs2_val;
    // end
    logic [4:0] destination_register;
    // Register write
    assign destination_register = inst_fields.rd;
    always_ff @(posedge clk) begin
        if (!rst && reg_write && inst_fields.rd != 0) begin
            if (mem_to_reg && !mem_read)
                registers[inst_fields.rd] <= dmem[alu_result];
            else if (jump)
                registers[inst_fields.rd] <= pc + 4;
            else if(!rst && mem_read)//load 
                registers[inst_fields.rd] <= load_result;
            else
                registers[inst_fields.rd] <= alu_result;
        end
    end
    // Branch unit
logic branch_taken;
logic [31:0] branch_target;

// Branch comparison logic
always_comb begin
    branch_taken = 1'b0;
    
    if (branch) begin
        case (inst_fields.funct3)
            3'b000: branch_taken = (rs1_val == rs2_val);              // BEQ
            3'b001: branch_taken = (rs1_val != rs2_val);              // BNE
            3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val));   // BLT
            3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));  // BGE
            3'b110: branch_taken = (rs1_val < rs2_val);               // BLTU
            3'b111: branch_taken = (rs1_val >= rs2_val);              // BGEU
            default: branch_taken = 1'b0;
        endcase
    end
end


endmodule
