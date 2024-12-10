`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module riscv_processor (
    input  wire       clk,
    input  wire        rst,
    input  wire [31:0] ending_pc,
  
    output logic [31:0] pc_out,
    output logic  instruction_done,
    
    output logic write_enable, 
    output logic [31:0] w_data,
    output logic [31:0] w_addr
);
    // Program Counter
    logic [31:0] pc;
    assign pc_out = pc;

    // logic [31:0] dmem [1023:0];  // Data memory

    logic [31:0] registers [31:0];
    logic registers_initialized;
    logic dmem_read;
    logic [31:0] aligned_addr;
    logic [31:0] load_value;
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
logic [31:0] f2d_inst;
logic [31:0] d2e_inst;
logic [31:0] e2m_inst;
logic [31:0] mem1_mem2_inst;
logic [31:0] mem2_wb_inst;

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
    logic branch;
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
        logic      mem_write;
        logic        valid;
        logic jump;
        logic [2:0] funct3;
        logic [31:0] rs2_val;
        logic branch;
    } m2w_type;


d2e_type d2e_reg;
f2d_type f2d_reg;
e2m_type e2m_reg;//request memory 
m2w_type mem1_mem2_reg;//wait one cycle 
m2w_type mem2_wb_reg;//write back


logic [31:0] fetch_1_pc;
logic fetch_1_valid;

logic [31:0] fetch_2_pc;
logic fetch_2_valid;

logic [31:0] fetch_3_pc;
logic fetch_3_valid; 

logic[31:0] f2d_pc;

logic[31:0] e2m_pc;
logic[31:0] d2e_pc;
logic[31:0] mem1_mem2_pc;

// writeback_type writeback_reg;
logic [31:0] data_to_write;

logic stall_decode;
logic memory_hazard;
    
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
   
// fetch_state_t fetch_state;
    // Initialize registers at start

    //Synthesis: `FPATH(instructionMem.mem)
    //simulation:absolute path 
   xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(2048),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(instructionMem.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
   ) imem (
    .addra(pc>>2),//what if we fetched next_pc     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(!stall_decode),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(1'b0),       // Output reset (does not affect memory contents)
    .regcea(!stall_decode),   // Output register enable
    .douta(douta)      // RAM output data, width determined from RAM_WIDTH
  );
    //`FPATH(dataMem.mem)
  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(1024),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(`FPATH(dataMem.mem))
) dmem (
    // Port A - Read port
    .clka(clk),
    .ena(dmem_read && !memory_hazard),
    .wea(1'b0),
    .addra(aligned_addr>>2),
    .dina(32'b0),
    .douta(load_value),//should be the load value from 2 cycles later 
    .rsta(rst),
    .regcea(1'b1),
    
    // Port B - Write port
    .enb(mem2_wb_reg.mem_write && mem2_wb_reg.valid),//last stage
    .web(1'b1),
    .addrb(mem2_wb_reg.alu_result>>2),
    .dinb(data_to_write),
    .doutb(),
    .rstb(rst),
    .regceb(1'b1)
);
assign write_enable = mem2_wb_reg.mem_write && mem2_wb_reg.valid;
assign w_data = data_to_write;
assign w_addr = mem2_wb_reg.alu_result>>2;



//     //CHECK FOR HAZARDS

    logic annul;
    assign fetch_1_pc = pc; 
    assign fetch_1_valid = rst? 0: 1'b1;

//SETTING FETCH STAGES TRANSITIOn
    always_ff@(posedge clk)begin 
        if(rst)begin 
           fetch_2_pc<=32'b0;
              fetch_2_valid<=0;
                fetch_3_pc<=32'b0;
                fetch_3_valid<=0;

        end
        else begin 
            if(stall_decode)begin 

                //keep everything the same
                // fetch_2_valid<=0;
                // fetch_3_valid<=0;

            end 
            else begin 
            fetch_2_pc<=fetch_1_pc;
            fetch_2_valid<=annul ? 0 : fetch_1_valid;

            fetch_3_pc<=fetch_2_pc;
            fetch_3_valid<=annul? 0 : fetch_2_valid;
            end 
        end
        
    end
    // Fetch state machine
    // logic [31:0] x3;
    // assign x3 = registers[3];
    logic [31:0] last_done_pc;
    assign instruction_done = last_done_pc == ending_pc;
    always_ff @(posedge clk)begin 
        if(rst)begin 
            registers_initialized<=1'b0;
            pc<=32'b0;

        end else if (!registers_initialized) begin
            // for (int i = 0; i < 32; i++) begin
            //     registers[i] <= 32'b0;
            // end
            
            registers_initialized <= 1'b1;

        end
        else begin 
         pc <=next_pc;
        end

    end
    // logic[31:0] x_4;
    // assign x_4 = registers[4];
    // logic [31:0] x_1,x_2;
    // assign x_1 = registers[1];
    // assign x_2 = registers[2];
    // Next PC Logic SHOULD BE DETERMINED IN EXECUTE 
    logic branch_d2e;
    assign branch_d2e = d2e_reg.branch;
    logic [31:0] next_pc;
    // logic [31:0] d2e_imm;
    // assign d2e_imm = d2e_reg.imm;
    always_comb begin
        annul= 1'b1;
        if (d2e_reg.jump && d2e_reg.alu_src)         // JALR
            next_pc = alu_result;
        else if (d2e_reg.jump)               // JAL
            next_pc = $signed(d2e_reg.pc) + $signed(d2e_reg.imm);
        else if (d2e_reg.branch && branch_taken)
            next_pc = $signed(d2e_reg.pc) + $signed(d2e_reg.imm);
        else begin 
            next_pc = stall_decode?pc : pc + 4;
            annul= 1'b0;
        end 
    
    end

    //FETCH SETUP + FETCH STATE
   always_ff @(posedge clk) begin
    if (rst) begin
        f2d_reg  <= '0;
        f2d_inst <= 32'b0;
    end else if (stall_decode) begin
        // Do nothing, hold current value of f2d_reg
    end else if (annul) begin
        // Flush the pipeline stage
        f2d_reg  <= '0;
        f2d_inst <= 32'b0;
    end else if (fetch_3_valid) begin
        f2d_reg.instruction <= douta;
        f2d_reg.pc          <= fetch_3_pc;
        f2d_reg.valid       <= 1'b1;
        f2d_inst            <= douta;
        f2d_pc              <= fetch_3_pc;
    end else begin
        // Hold f2d_reg (do nothing)
    end
end

    //DECODE SETUP
    // logic [31:0] rs1_debug;
    // logic [31:0] rs2_debug;
    // logic [31:0] rd_debug;

    // assign rs1_debug = rs1_val;
    // assign rs2_debug = rs2_val;
    // assign rd_debug = rd_val;
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
        else begin 
            inst_fields = 32'b0;
            imm = 32'b0;
            rs1_val = 32'b0;
            rs2_val = 32'b0;

        end 
    end 
        //decode 
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
            d2e_reg<=157'b0;
            d2e_inst<=32'b0;
        end
        else begin 
            if(stall_decode&&!memory_hazard)begin 
                //do nothing
                d2e_reg<=158'b0;
            end
            else if(memory_hazard)begin 
            //do nothing
            end
            else if(f2d_reg.valid && !annul)begin 
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
                d2e_inst<=f2d_inst;
                d2e_pc<=f2d_pc;
            end
         
            
            else begin  
                d2e_reg<='0;
                d2e_inst<=32'b0;
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
    logic [31:0] rs1_d2e,rs2_d2e;
    logic [31:0] rs1_e2m,rs2_e2m;
    logic [31:0] rs1_m1,rs2_m1;
    logic [31:0] rs1_wb,rs2_wb;

    // Execute to Memory Register
    always_ff @(posedge clk) begin
        if (rst) begin
            e2m_reg <= 110'b0;
            e2m_inst<=32'b0;
        end 
        else if (memory_hazard) begin
            //do nothing  keep this memory the same

        end
        else begin
            if (d2e_reg.valid ) begin
                e2m_reg.pc <= d2e_reg.pc;
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
                e2m_reg.branch     <= d2e_reg.branch;
                e2m_inst<=d2e_inst;
                e2m_pc<=d2e_pc;
            end else begin
                e2m_reg<='0;
            end
        end
    end



    
    //Memory Request

    assign aligned_addr = {e2m_reg.alu_result[31:2], 2'b00};
    assign dmem_read = e2m_reg.mem_read||e2m_reg.mem_write;//since we need the write data for partial stores 

    //transitions 
        // Memory to Writeback Register
    always_ff @(posedge clk) begin
        if (rst || memory_hazard) begin
            mem1_mem2_reg <= 106'b0;

        end else begin
            if (e2m_reg.valid) begin
                mem1_mem2_reg.pc         <= e2m_reg.pc;
                mem1_mem2_reg.alu_result <= e2m_reg.alu_result;
                mem1_mem2_reg.mem_data   <= load_result;
                mem1_mem2_reg.rd         <= e2m_reg.rd;
                mem1_mem2_reg.reg_write  <= e2m_reg.reg_write;
                mem1_mem2_reg.mem_to_reg <= e2m_reg.mem_to_reg;
                mem1_mem2_reg.valid      <= e2m_reg.valid;
                mem1_mem2_reg.jump       <= e2m_reg.jump;
                mem1_mem2_reg.mem_read   <= e2m_reg.mem_read;
                mem1_mem2_reg.mem_write  <= e2m_reg.mem_write;
                mem1_mem2_reg.funct3     <= e2m_reg.funct3;
                mem1_mem2_reg.rs2_val    <= e2m_reg.rs2_val;
                mem1_mem2_reg.branch     <= e2m_reg.branch;
                // m2w_inst<=e2m_inst;
                mem1_mem2_inst<=e2m_inst;
                mem1_mem2_pc<=e2m_pc;

            end else begin
                mem1_mem2_reg<=106'b0;   
            end
        end
    end
    always_ff@(posedge clk )begin 
        if(!rst)begin  
            mem2_wb_reg<=mem1_mem2_reg;
            mem2_wb_inst<=mem1_mem2_inst;
        end
        else begin 
            mem2_wb_reg<=106'b0;
        end

    end 
    logic mem1_mem_hazard;
    logic mem2_mem_hazard;

    always_comb begin 
        //its a store if mem_write is 1 abd load if mem_read us 1
        //check if we're writing to the same place we're reading from 
        mem1_mem_hazard = e2m_reg.mem_read && mem1_mem2_reg.mem_write && (aligned_addr == (mem1_mem2_reg.alu_result & 32'hFFFFFFFC));
        mem2_mem_hazard = e2m_reg.mem_read && mem2_wb_reg.mem_write && (aligned_addr == (mem2_wb_reg.alu_result & 32'hFFFFFFFC));
        memory_hazard = mem1_mem_hazard || mem2_mem_hazard;


    end 
    //MEMORY STAGE STUFF 
    logic [3:0] memory_store_enable;
    logic [31:0] final_store_data;

    logic [31:0] load_result;
    logic [1:0] byte_offset;
//     logic is_unsigned;


//     // Extract byte offset and aligned address
    assign byte_offset = mem2_wb_reg.alu_result[1:0];
//     assign aligned_addr = {e2m_reg.alu_result[31:2], 2'b00};
//         //mem_rdata is aligned_addr 
 
//     // Load operation implementation
    // logic [31:0] load_value;
    Mem_ctrl_unit mem_ctrl_unit(
        .clk(clk),
        .rst(rst),
        .funct3(mem2_wb_reg.funct3),
        .byte_offset(byte_offset),
        .rs2_val(mem2_wb_reg.rs2_val),
        .mem_rdata(load_value),
        .read_result(load_result),
        .mem_wdata(final_store_data),
        .mem_be(memory_store_enable)
    );

// MEM WRITE 

always_comb begin
    if (!rst && mem2_wb_reg.mem_write && mem2_wb_reg.valid) begin
        data_to_write[7:0] =  memory_store_enable[0]? final_store_data[7:0]:load_value[7:0];
        data_to_write[15:8] = memory_store_enable[1]? final_store_data[15:8]:load_value[15:8];
        data_to_write[23:16] = memory_store_enable[2]? final_store_data[23:16]:load_value[23:16];
        data_to_write[31:24] = memory_store_enable[3]? final_store_data[31:24]:load_value[31:24];

    end
    else begin 
        data_to_write = 32'b0;

    end 
end



    //WB
    logic [4:0] destination_register;
    // Register write
    assign destination_register = mem2_wb_reg.rd;
    // logic reg_write_1;
    // assign reg_write_1 = mem2_wb_reg.reg_write;   
    // logic mem_read_1;
    // assign mem_read_1 = mem2_wb_reg.mem_read;
    // logic [31:0] load_data_ending;
    // assign load_data_ending = mem2_wb_reg.mem_data;
    // logic [31:0] wb_alu_result;
    // assign wb_alu_result = mem2_wb_reg.alu_result;
    
    always_ff @(posedge clk) begin
        if(!registers_initialized)begin
            for(int i =0;i<32;i++)begin
                registers[i]<=32'b0;
            end
        end
        else
        if (!rst && mem2_wb_reg.reg_write && destination_register != 0) begin
            if (mem2_wb_reg.mem_to_reg && !mem2_wb_reg.mem_read)
            //difference between load value and load result is that one goes through filtering for lb and lbu and lh etc
                registers[destination_register] <= load_value;
            else if (mem2_wb_reg.jump) // JALR
                registers[destination_register] <= mem2_wb_reg.pc + 4;
            else if(!rst && mem2_wb_reg.mem_read)//load 
                registers[destination_register] <= load_result;
            else if(!mem2_wb_reg.branch)
                registers[destination_register] <= mem2_wb_reg.alu_result;

            else begin 

                //nothing
            end 
        end
    end
    always_ff@(posedge clk)begin 
        if(!rst && mem2_wb_reg.valid)begin 
            last_done_pc<=mem2_wb_reg.pc;
        end
    end
    logic [31:0] current_wb_pc;
    always_comb begin 
        current_wb_pc = mem2_wb_reg.pc;
    end
    //HAZARD DETECTION if any of the decode rs1 or rs2 are the same as ANY downstrem rd then stall 
    // logic stall_decode;
    logic exec_hazard;
    logic mem_hazard;
    logic mem2_hazard;
    logic wb_hazard;
    always_comb begin 
        // stall_decode = 0;
        exec_hazard = (inst_fields.rs1 == d2e_reg.rd || inst_fields.rs2 == d2e_reg.rd) && d2e_reg.valid && !annul && d2e_reg.rd!=0;
        mem_hazard = ((inst_fields.rs1 == e2m_reg.rd || inst_fields.rs2 == e2m_reg.rd) && e2m_reg.valid && e2m_reg.rd!=0);
        mem2_hazard = ((inst_fields.rs1 == mem1_mem2_reg.rd || inst_fields.rs2 == mem1_mem2_reg.rd) && mem1_mem2_reg.valid && mem1_mem2_reg.rd!=0);
        wb_hazard = ((inst_fields.rs1 == mem2_wb_reg.rd || inst_fields.rs2 == mem2_wb_reg.rd) && mem2_wb_reg.valid && mem2_wb_reg.rd!=0);
        stall_decode = exec_hazard || mem_hazard || mem2_hazard || wb_hazard;
        // stall_decode = 0;

        end
    //  assign stall_decode= 0;
    // Branch unit




endmodule
`default_nettype none
