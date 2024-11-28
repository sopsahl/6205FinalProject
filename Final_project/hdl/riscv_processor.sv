module riscv_processor (
    input  logic        clk,
    input  logic        rst,
  
    output logic [31:0] pc_out,
    output logic  instruction_done
);
    // Program Counter
    logic [31:0] pc;
    assign pc_out = pc;
    // logic [31:0] next_pc;
    // Memory and Registers
    // logic [31:0] imem [1023:0];  // Instruction memory
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
    logic [31:0] douta;
    typedef enum logic [1:0] {
      FETCH_REQUEST,
      FETCH_WAIT,
      FETCH_AVAILABLE
    } fetch_state_e;
    fetch_state_e fetch_state;
// fetch_state_t fetch_state;
    // Initialize registers at start
   xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE("/Users/ziyadhassan/6205/6205FinalProject/Final_project/data/instructionMem.mem")          // Specify name/location of RAM initialization file if using one (leave blank if not)
   ) imem (
    .addra(pc>>2),     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(fetch_state==FETCH_REQUEST),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(1'b0),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(douta)      // RAM output data, width determined from RAM_WIDTH
  );
    // Fetch state machine
    logic data_ready;
    assign instruction_done = fetch_state==FETCH_AVAILABLE;
    always_ff @(posedge clk)begin 
        if(rst)begin 
            registers_initialized<=1'b0;
            pc<=32'b0;
        end else if (!registers_initialized) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
            for(int i=0;i<1024;i++)begin
                // imem[i]<=32'b0;
                dmem[i]<=32'b0;
            end
            registers_initialized <= 1'b1;
            fetch_state<=FETCH_REQUEST;

        end
        else begin 
            case(fetch_state)
                FETCH_REQUEST:begin
                    fetch_state<=FETCH_WAIT;
                end
                FETCH_WAIT:begin
                    fetch_state<=FETCH_AVAILABLE;
                end
                FETCH_AVAILABLE:begin
                    fetch_state<=FETCH_REQUEST;
                    if(jump && alu_src)//jalr
                        pc <= alu_result;
                    else if (jump )//jal
                        pc <= pc + imm;
                    else if (branch && branch_taken)
                        pc <= pc + imm;
            
                    else
                        pc <= pc + 4;  // Increment by 1 instead of 4 for debugging
                end
                
            endcase
        
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
    assign instruction = fetch_state==FETCH_AVAILABLE?douta:32'b0;
    
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
    
    always_comb begin 
        imm = generate_imm(instruction,inst_fields.opcode);

    end

    // Register read
    assign rs1_val = registers[inst_fields.rs1];
    assign rs2_val = (inst_fields.opcode == 7'b0010011) ? imm :registers[inst_fields.rs2];

   
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

    // always_comb begin
    //     case (alu_ctrl)
    //         4'b0000: alu_result = rs1_val + (alu_src ? imm : rs2_val); // ADD
    //         4'b0001: alu_result = rs1_val - rs2_val; // SUB
    //         4'b0010: alu_result = rs1_val & rs2_val; // AND
    //         4'b0011: alu_result = rs1_val | rs2_val; // OR
    //         4'b0100: alu_result = rs1_val ^ rs2_val; // XOR
    //         4'b0101: alu_result = rs1_val << rs2_val[4:0]; // SLL
    //         4'b0110: alu_result = rs1_val >> rs2_val[4:0]; // SRL
    //         4'b0111: alu_result = $signed(rs1_val) >>> rs2_val[4:0]; // SRA
    //         4'b1000: alu_result = $signed(rs1_val) < $signed(rs2_val) ? 32'd1 : 32'd0; // SLT
    //         4'b1001: alu_result = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
    //         4'b1010: alu_result = imm; // LUI
    //         4'b1011: alu_result = pc + imm;             // AUIPC

    //         default: alu_result = rs1_val + (alu_src ? imm : rs2_val);
    //     endcase
    // end

    ALU alu(
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .imm(imm),
        .pc(pc),
        .alu_ctrl(alu_ctrl),
        .alu_src(alu_src),
        .alu_result(alu_result)
    );
    // logic [31:0] load_result;
    // logic [31:0] store_data;
    logic [3:0] memory_store_enable;
    logic [31:0] final_store_data;

    logic [31:0] load_result;
    logic [1:0] byte_offset;
    logic [31:0] aligned_addr;
    logic is_unsigned;


    // Extract byte offset and aligned address
    assign byte_offset = alu_result[1:0];
    assign aligned_addr = {alu_result[31:2], 2'b00};
        //mem_rdata is aligned_addr 

    // Load operation implementation
    logic [31:0] load_value;
    assign load_value = dmem[aligned_addr];
    Mem_ctrl_unit mem_ctrl_unit(
        .clk(clk),
        .rst(rst),
        .funct3(inst_fields.funct3),
        .byte_offset(byte_offset),
        .rs2_val(rs2_val),
        .mem_rdata(load_value),
        .read_result(load_result),
        .mem_wdata(final_store_data),
        .mem_be(memory_store_enable)
    );

// Write to memory
always_ff @(posedge clk) begin
    if (!rst && mem_write) begin
        if (memory_store_enable[0]) dmem[aligned_addr][7:0] <= final_store_data[7:0];
        if (memory_store_enable[1]) dmem[aligned_addr][15:8] <= final_store_data[15:8];
        if (memory_store_enable[2]) dmem[aligned_addr][23:16] <= final_store_data[23:16];
        if (memory_store_enable[3]) dmem[aligned_addr][31:24] <= final_store_data[31:24];
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

// // Branch comparison logic
// always_comb begin
//     branch_taken = 1'b0;
    
//     if (branch) begin
//         case (inst_fields.funct3)
//             3'b000: branch_taken = (rs1_val == rs2_val);              // BEQ
//             3'b001: branch_taken = (rs1_val != rs2_val);              // BNE
//             3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val));   // BLT
//             3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));  // BGE
//             3'b110: branch_taken = (rs1_val < rs2_val);               // BLTU
//             3'b111: branch_taken = (rs1_val >= rs2_val);              // BGEU
//             default: branch_taken = 1'b0;
//         endcase
//     end
// end
branch_unit bu(
    .branch(branch),
    .funct3(inst_fields.funct3),
    .rs1_val(rs1_val),
    .rs2_val(rs2_val),
    .branch_taken(branch_taken)
);


endmodule
