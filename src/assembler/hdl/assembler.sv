`timescale 1ns / 1ps
`default_nettype none

import assembler_constants::*;

typedef enum {
    IDLE,
    PC_MAPPING,
    INSTRUCTION_MAPPING,
    ERROR
} assembler_state;

module assembler #(
    parameter CHAR_PER_LINE = 64
    ) (     
    input wire clk_in,
    input wire rst_in,
    input wire new_line, 
    input wire new_character,
    input wire [7:0] incoming_character, // Each new character 
    output logic done_flag, // Instruction is Ready
    output logic error_flag, // Error encountered

    input assembler_state assembler_state, // Determines what we are doing at any given point
    output logic [31:0] instruction
);  

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
        DONE,
        ERROR
    } inst_state instruction_state;

    inst_state next_instruction_state;

    always_comb begin
        case (inst.opcode) 
            OP_REG : next_instruction_state = (instruction_state == READ_INST) ? 
            OP_IMM : return {inst.imm[11:5] && inst.funct7, inst.imm[4:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
            OP_LOAD, OP_JALR : return {inst.imm[11:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
            OP_STORE : return {inst.imm[11:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:0], inst.opcode};
            OP_BRANCH : return {inst.imm[12], inst.imm[10:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:1], inst.imm[11], inst.opcode};
            OP_LUI, OP_AUIPC : return {inst.imm[31:12], inst.rd, inst.opcode};
            OP_JAL : return {inst.imm[20], inst.imm[10:1], inst.imm[11], inst.imm[19:12], inst.rd, inst.opcode};
            default: next_state = IDLE;
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
    logic inst_busy, reg_busy, imm_busy;

    instruction_interpreter get_inst (
        .clk_in(clk_in),
        .rst_in(rst_in || new_line),
        .valid_data(instruction_state == READ_INST),
        .new_character(new_character),
        .incoming_ascii(incoming_character),
        .error_flag(inst_error),
        .done_flag(inst_done),
        .busy_flag(inst_busy),
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
        .busy_flag(reg_flag),
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
        .busy_flag(imm_busy),
        .isUtype((inst.opcode == OP_AUIPC) || (inst.opcode == OP_LUI)),
        .immediate(immediate_buffer)
    );

    // *****************************************


    // always_ff @(posedge clk_in) begin

    //         if (rst_in) begin
    //             state <= IDLE;
    //             ready_flag <= 1'b0;
    //             error_flag <= 1'b0;
    //         end else begin
    //             case (state) 
    //                 IDLE: begin // Waiting for a ne       w line
    //                     if (new_line) 
    //                 end READ_INST: begin

    //                 end READ_REG: begin

    //                 end READ_IMM: begin

    //                 end READ_LABEL: begin
                        
    //                 end DONE: begin

    //                 end 

    //                 end

    //             endcase

    //             count <= (count == period_in - 1) ? 0 : count + 1;
    //             count_done <= (count == period_in - 1);

    //         end

    //     end

endmodule 

`default_nettype wire
