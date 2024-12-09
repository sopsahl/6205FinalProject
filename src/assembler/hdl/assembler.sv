`timescale 1ns / 1ps
`default_nettype none

import constants::*;

module assembler #(
    parameter CHAR_PER_LINE = 64,
    parameter NUMBER_LINES = 256,
    parameter NUM_LABELS = 8,
    parameter LABEL_SIZE = 6
    ) (     
    input wire clk_in,
    input wire rst_in,
    input wire new_line, 
    input wire new_character,
    input wire [$clog2(NUMBER_LINES) - 1 : 0] line_count,
    input wire [$clog2(CHAR_PER_LINE) - 1 : 0] char_count,
    input wire [7:0] incoming_character, // Each new character 
    output logic done_flag, // Instruction is Ready
    output logic error_flag, // Error encountered

    input assembler_state_t assembler_state, // Determines what we are doing at any given point
    output logic [31:0] instruction,
    output logic new_instruction
);  

    assign error_flag = inst_error || imm_error || reg_error || label_error; 
    assign new_instruction = new_instruction_buffer;
    assign done_flag = (new_instruction) || (label_done && assembler_state == PC_MAPPING);

    // *****************************************
    // State Logic for Instruction Mapping

    InstFields inst; // maps the different fields of the instruction

    typedef enum {
        IDLE,
        READ_INST,
        READ_RD,
        READ_RS1,
        READ_RS2,
        READ_IMM,
        READ_LABEL,
        DONE
    } inst_state;

    inst_state instruction_state;
    inst_state next_instruction_state;

    logic [6:0] opcode;
    assign opcode = (instruction_state == READ_INST) ? opcode_buffer : inst.opcode;

    always_comb begin
        // case (inst.opcode) // For builds
        case (opcode) // For Simulation
            OP_REG : next_instruction_state = (instruction_state == READ_INST) ? READ_RD :
                            (instruction_state == READ_RD) ? READ_RS1 : (instruction_state == READ_RS1) ? READ_RS2 : (instruction_state == READ_RS2) ? DONE : IDLE;
            OP_IMM, OP_LOAD, OP_STORE, OP_JALR: next_instruction_state = (instruction_state == READ_INST) ? READ_RD :
                            (instruction_state == READ_RD) ? READ_RS1 : (instruction_state == READ_RS1) ? READ_IMM : (instruction_state == READ_IMM) ? DONE : IDLE;
            OP_BRANCH : next_instruction_state = (instruction_state == READ_INST) ? READ_RS1 :
                            (instruction_state == READ_RS1) ? READ_RS2 : (instruction_state == READ_RS2) ? READ_LABEL : (instruction_state == READ_LABEL) ? DONE : IDLE;
            OP_LUI, OP_AUIPC : next_instruction_state = (instruction_state == READ_INST) ? READ_RD :
                            (instruction_state == READ_RD) ? READ_IMM : (instruction_state == READ_IMM) ? DONE : IDLE;
            OP_JAL : next_instruction_state = (instruction_state == READ_INST) ? READ_RD :
                            (instruction_state == READ_RD) ? READ_LABEL : (instruction_state == READ_LABEL) ? DONE : IDLE;
            default: next_instruction_state = IDLE;
        endcase
    end

    // *****************************************
    // *****************************************
    // Interpreter Modules

    logic [6:0] opcode_buffer;
    logic [6:0] funct7_buffer;
    logic [2:0] funct3_buffer;
    logic [4:0] reg_buffer;
    logic [31:0] immediate_buffer;

    logic inst_error, reg_error, imm_error;
    logic inst_done, reg_done, imm_done;

    instruction_interpreter get_inst (
        .clk_in(clk_in),
        .rst_in(rst_in || new_line),
        .valid_data(instruction_state == READ_INST),
        .new_character(new_character),
        .incoming_ascii(incoming_character),
        .error_flag(inst_error),
        .done_flag(inst_done),
        .opcode(opcode_buffer),
        .funct7(funct7_buffer),
        .funct3(funct3_buffer)
    );

    register_interpreter get_reg (
        .clk_in(clk_in),
        .rst_in(rst_in || new_line),
        .valid_data(instruction_state == READ_RD || instruction_state == READ_RS1 || instruction_state == READ_RS2),
        .new_character(new_character),
        .incoming_ascii(incoming_character),
        .error_flag(reg_error),
        .done_flag(reg_done),
        .register(reg_buffer)
    );

    immediate_interpreter get_imm (
        .clk_in(clk_in),
        .rst_in(rst_in || new_line),
        .valid_data(instruction_state == READ_IMM),
        .new_character(new_character),
        .incoming_ascii(incoming_character),
        .error_flag(imm_error),
        .done_flag(imm_done),
        .isUtype((inst.opcode == OP_AUIPC) || (inst.opcode == OP_LUI)),
        .immediate(immediate_buffer)
    );

    // *****************************************
    // *****************************************
    // Label Controller

    logic [31:0] offset;
    logic label_error, label_done;
    
    label_controller #(.NUMBER_LINES(NUMBER_LINES), .NUMBER_LETTERS(LABEL_SIZE), .NUM_LABELS(NUM_LABELS)) label_controller (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .new_line(new_line),
        .new_character(new_character),
        .valid_data(instruction_state == READ_LABEL || assembler_state == PC_MAPPING),
        .pc(pc),
        .incoming_character(incoming_character),
        .done_flag(label_done),
        .error_flag(label_error),
        .assembler_state(assembler_state),
        .offset(offset)
    );

    // *****************************************
    // *****************************************
    // PC logic

    logic [$clog2(NUMBER_LINES) + 1 : 0] label_pc;
    logic [$clog2(NUMBER_LINES) + 1 : 0] inst_pc;
    logic [$clog2(NUMBER_LINES) + 1 : 0] pc;

    pc_mapping #(.NUMBER_LINES(NUMBER_LINES)) label_pc_counter (
        .clk_in(clk_in),
        .rst_in(assembler_state != PC_MAPPING || rst_in),
        .new_line(new_line),
        .new_character(new_character),
        .incoming_ascii(incoming_character),
        .pc(label_pc)
    );

    pc_counter #(.NUMBER_LINES(NUMBER_LINES)) inst_pc_counter (
        .clk_in(clk_in),
        .rst_in((assembler_state != INSTRUCTION_MAPPING) || rst_in),
        .evt_in(instruction_state == DONE),
        .count_out(inst_pc)
    );

    assign pc = (assembler_state == PC_MAPPING) ? label_pc : inst_pc;

    // *****************************************
    // *****************************************
    // INSTRUCTION_MAPPING STATE LOGIC

    logic inst_ready_buffer, new_instruction_buffer =0;

    always_ff @(posedge clk_in) begin
        if (assembler_state == INSTRUCTION_MAPPING && !rst_in) begin
            case (instruction_state)
                READ_INST : begin
                    if (inst_done) begin
                        inst.opcode <= opcode_buffer;
                        inst.funct3 <= funct3_buffer;
                        inst.funct7 <= funct7_buffer;
                    end
                end READ_RD : if (reg_done) inst.rd <= reg_buffer;
                READ_RS1 : if (reg_done) inst.rs1 <= reg_buffer;
                READ_RS2 : if (reg_done) inst.rs2 <= reg_buffer;
                READ_IMM : if (imm_done) inst.imm <= immediate_buffer;
                READ_LABEL : if (label_done) inst.imm <= offset;
                DONE : instruction <= create_inst(inst); // Create the instruction
            endcase 

            instruction_state <= (new_line) ? READ_INST :
                (((incoming_character == "/" || incoming_character == "'") && instruction_state == READ_INST) || instruction_state == DONE) ? IDLE :
                (label_done || imm_done || inst_done || reg_done) ? next_instruction_state : instruction_state;
            
            // Buffers
            // inst_ready_buffer <= inst_done; // We have a cycle delay for the instruction
            new_instruction_buffer <= instruction_state == DONE; // Store a cycle delay
        
        end else instruction_state <= IDLE; // Either Reset or different State

    end

    // *****************************************


endmodule // assembler

function logic [31:0] create_inst(InstFields inst);
    case (inst.opcode) 
        OP_REG : return {inst.funct7, inst.rs2, inst.rs1, inst.funct3, inst.rd, inst.opcode};
        OP_IMM : return {inst.imm[11:5] | inst.funct7, inst.imm[4:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
        OP_LOAD, OP_JALR : return {inst.imm[11:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
        OP_STORE : return {inst.imm[11:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:0], inst.opcode};
        OP_BRANCH : return {inst.imm[12], inst.imm[10:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:1], inst.imm[11], inst.opcode};
        OP_LUI, OP_AUIPC : return {inst.imm[19:0], inst.rd, inst.opcode};
        OP_JAL : return {inst.imm[20], inst.imm[10:1], inst.imm[11], inst.imm[19:12], inst.rd, inst.opcode};
        default: return 32'b0;
    endcase
endfunction

`default_nettype wire
