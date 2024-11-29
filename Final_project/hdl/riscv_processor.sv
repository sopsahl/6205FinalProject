module riscv_processor (
    input  logic        clk,
    input  logic        rst,
  
    output logic [31:0] pc_out,
    output logic  instruction_done
);
    // Program Counter
    logic [31:0] pc;
    assign pc_out = pc;

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
    typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instruction;
    logic        valid;
    } f2d_type;

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] imm;
    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [2:0]  funct3;
    logic        reg_write;
    logic        mem_to_reg;
    logic        mem_read;
    logic        mem_write;
    logic        alu_src;
    logic        branch;
    logic        jump;
    logic [3:0]  alu_ctrl;
    logic        valid;
} d2e_type;

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] alu_result;
    logic [31:0] rs2_val;
    logic [4:0]  rd;
    logic   [2:0] funct3;
    logic        reg_write;
    logic        mem_to_reg;
    logic        mem_read;
    logic        mem_write;
    logic        valid;
    logic jump;//for dest pc purposes, I know I should have handled that earlier lol
} e2m_type;

  typedef struct packed {
        logic [31:0] pc;
        logic [31:0] alu_result;
        logic [31:0] mem_data;
        logic [4:0]  rd;
        logic        reg_write;
        logic        mem_to_reg;
        logic       mem_read;
        logic        valid;
        logic jump;
    } m2w_type;


d2e_type d2e_reg;
f2d_type f2d_reg;
e2m_type e2m_reg;
m2w_type m2w_reg;


// writeback_type writeback_reg;

logic flush_pipeline;
logic stall_fetch;
logic stall_decode;
    
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
      FETCH_WAIT1,
      FETCH_WAIT2
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
//     //CHECK FOR HAZARDS
//     always_comb begin
//     stall_pipeline = 1'b0;
    
//     // RAW Hazard detection
//     if (decode_reg.mem_read && 
//         ((decode_reg.rd == inst_fields.rs1 && inst_fields.rs1 != 0) || 
//          (decode_reg.rd == inst_fields.rs2 && inst_fields.rs2 != 0))) begin
//         // stall_pipeline = 1'b1;
//         stall_fetch = 1'b1;
//         stall_decode = 1'b1;
//     end
// end


    // Fetch state machine
    logic data_ready;
    assign instruction_done = m2w_reg.valid;
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
                    fetch_state<=FETCH_WAIT1;
                end
                FETCH_WAIT1:begin
                    fetch_state<=FETCH_WAIT2;
                end
                FETCH_WAIT2:begin
                    //SHOULD BE DONE IN SYNC WITH LAST WB STAGE 
                    // fetch_state<=FETCH_REQUEST;
                    // if(jump && alu_src)//jalr
                    //     pc <= alu_result;
                    // else if (jump )//jal
                    //     pc <= pc + imm;
                    // else if (branch && branch_taken)
                    //     pc <= pc + imm;
            
                    // else
                    //     pc <= pc + 4;  // Increment by 1 instead of 4 for debugging
                    fetch_state<=FETCH_REQUEST;
                    pc<=next_pc;// That way we have already determined what next pc is
                end
                
            endcase
        
        end

    end
    // Next PC Logic;; this is supposed to happen in execute stage, also probably always going to work THIS IS DIETERMINED IN EXECUTE
    logic [31:0] next_pc;
    always_comb begin
        if (jump && alu_src)         // JALR
            next_pc = alu_result;
        else if (jump)               // JAL
            next_pc = d2e_reg.pc + d2e_reg.imm;
        else if (branch && branch_taken)
            next_pc = d2e_reg.pc + d2e_reg.imm;
        else
            next_pc = d2e_reg.pc + 4;
    end

    //FETCH 

    always_ff @(posedge clk) begin
        if (!rst) begin
            //FETCH wait 2 is when it's availble
            if (fetch_state == FETCH_WAIT2) begin
                f2d_reg.instruction  <= douta;
                f2d_reg.pc <= pc;
                f2d_reg.valid <= 1'b1;
            end
        end
    end

    //DECODE SETUP

    always_comb begin
        if (f2d_reg.valid) begin
            inst_fields.opcode = f2d_reg.instruction[6:0];
            inst_fields.rd = f2d_reg.instruction[11:7];
            inst_fields.funct3 = f2d_reg.instruction[14:12];
            inst_fields.rs1 = f2d_reg.instruction[19:15];
            inst_fields.rs2 = f2d_reg.instruction[24:20];
            inst_fields.funct7 = f2d_reg.instruction[31:25];
            instruction = f2d_reg.instruction;
            imm = generate_imm(instruction,inst_fields.opcode);

            rs1_val = registers[inst_fields.rs1];
            rs2_val = registers[inst_fields.rs2];

        end
    end 

         control_unit ctrl(
        .opcode(inst_fields.opcode),
        .funct3(inst_fields.funct3),
        .funct7(inst_fields.funct7),
        .imm(imm),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl)
    );
    //DECODE TRANSITION

    always_ff@(posedge clk) begin 
        if(rst) begin 
            d2e_reg<='0;
        end
        else begin 
            if(f2d_reg.valid)begin 
                d2e_reg.pc<=f2d_reg.pc;
                d2e_reg.rs1_val<=rs1_val;
                d2e_reg.rs2_val<=rs2_val;
                d2e_reg.imm<=imm;
                d2e_reg.rd<=inst_fields.rd;
                d2e_reg.rs1<=inst_fields.rs1;
                d2e_reg.rs2<=inst_fields.rs2;
                d2e_reg.funct3<=inst_fields.funct3;
                d2e_reg.reg_write<=reg_write;
                d2e_reg.mem_to_reg<=mem_to_reg;
                d2e_reg.mem_read<=mem_read;
                d2e_reg.mem_write<=mem_write;
                d2e_reg.alu_src<=alu_src;
                d2e_reg.branch<=branch;
                d2e_reg.jump<=jump;
                d2e_reg.alu_ctrl<=alu_ctrl;
                d2e_reg.valid<=1'b1;
            end
            else begin  
                d2e_reg<='0;
            end

        end

    end

    logic branch_taken;

    //EXECUTE
     // Execute Stage
    ALU alu(
        .rs1_val   (d2e_reg.rs1_val),
        .rs2_val   (d2e_reg.rs2_val),
        .imm       (d2e_reg.imm),
        .pc        (d2e_reg.pc),
        .alu_ctrl  (d2e_reg.alu_ctrl),
        .alu_src   (d2e_reg.alu_src),
        .alu_result(alu_result)
    );

    branch_unit bu(
        .branch      (d2e_reg.branch),
        .funct3      (d2e_reg.funct3),
        .rs1_val     (d2e_reg.rs1_val),
        .rs2_val     (d2e_reg.rs2_val),
        .branch_taken(branch_taken)
    );

    // Execute to Memory Register
    always_ff @(posedge clk) begin
        if (rst) begin
            e2m_reg <= '0;
        end else begin
            if (d2e_reg.valid) begin
                e2m_reg.pc         <= d2e_reg.pc;
                e2m_reg.alu_result <= alu_result;
                e2m_reg.rs2_val    <= d2e_reg.rs2_val;
                e2m_reg.rd         <= d2e_reg.rd;
                e2m_reg.funct3     <= d2e_reg.funct3;
                e2m_reg.reg_write  <= d2e_reg.reg_write;
                e2m_reg.mem_to_reg <= d2e_reg.mem_to_reg;
                e2m_reg.mem_read   <= d2e_reg.mem_read;
                e2m_reg.mem_write  <= d2e_reg.mem_write;
                e2m_reg.valid      <= d2e_reg.valid;
                e2m_reg.jump       <= d2e_reg.jump;
            end else begin
                e2m_reg<='0;
            end
        end
    end



  //MEM
    //MEMORY STAGE STUFF 
    logic [3:0] memory_store_enable;
    logic [31:0] final_store_data;

    logic [31:0] load_result;
    logic [1:0] byte_offset;
    logic [31:0] aligned_addr;
    logic is_unsigned;


    // Extract byte offset and aligned address
    assign byte_offset = e2m_reg.alu_result[1:0];
    assign aligned_addr = {e2m_reg.alu_result[31:2], 2'b00};
        //mem_rdata is aligned_addr 

    // Load operation implementation
    logic [31:0] load_value;
    assign load_value = dmem[aligned_addr];
    Mem_ctrl_unit mem_ctrl_unit(
        .clk(clk),
        .rst(rst),
        .funct3(e2m_reg.funct3),
        .byte_offset(byte_offset),
        .rs2_val(e2m_reg.rs2_val),
        .mem_rdata(load_value),
        .read_result(load_result),
        .mem_wdata(final_store_data),
        .mem_be(memory_store_enable)
    );

// MEM WRITE 
always_ff @(posedge clk) begin
    if (!rst && e2m_reg.mem_write && e2m_reg.valid) begin
        if (memory_store_enable[0]) dmem[aligned_addr][7:0] <= final_store_data[7:0];
        if (memory_store_enable[1]) dmem[aligned_addr][15:8] <= final_store_data[15:8];
        if (memory_store_enable[2]) dmem[aligned_addr][23:16] <= final_store_data[23:16];
        if (memory_store_enable[3]) dmem[aligned_addr][31:24] <= final_store_data[31:24];
    end
end
    // Memory to Writeback Register
    always_ff @(posedge clk) begin
        if (rst) begin
            m2w_reg <= '0;
        end else begin
            if (e2m_reg.valid) begin
                m2w_reg.pc         <= e2m_reg.pc;
                m2w_reg.alu_result <= e2m_reg.alu_result;
                m2w_reg.mem_data   <= load_result;
                m2w_reg.rd         <= e2m_reg.rd;
                m2w_reg.reg_write  <= e2m_reg.reg_write;
                m2w_reg.mem_to_reg <= e2m_reg.mem_to_reg;
                m2w_reg.valid      <= e2m_reg.valid;
                m2w_reg.jump       <= e2m_reg.jump;
                m2w_reg.mem_read   <= e2m_reg.mem_read;
            end else begin
                m2w_reg<=106'b0;   
            end
        end
    end

    //WB
    logic [4:0] destination_register;
    // Register write
    assign destination_register = m2w_reg.rd;
    logic reg_write_1;
    assign reg_write_1 = m2w_reg.reg_write;   
    always_ff @(posedge clk) begin
        if (!rst && m2w_reg.reg_write && destination_register != 0) begin
            if (mem_to_reg && !m2w_reg.mem_read)
                registers[destination_register] <= dmem[m2w_reg.alu_result];
            else if (jump)
                registers[destination_register] <= m2w_reg.pc + 4;
            else if(!rst && m2w_reg.mem_read)//load 
                registers[destination_register] <= load_result;
            else
                registers[destination_register] <= m2w_reg.alu_result;
        end
    end
    // Branch unit




endmodule
