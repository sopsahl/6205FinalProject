`timescale 1ns / 1ps
`default_nettype none

// instruction_interpreter: gets the instruction (e.g. and, xor, ...)
// Calculates the corresponding opcode, funct7, funct3
// Up to 5 characters
// done_flag high one cycle after delimiter (" " or ",")

import assembler_constants::*;

module instruction_interpreter (
    input wire clk_in,
    input wire rst_in,
    input wire valid_data,
    input wire new_character,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,
    output logic busy_flag,

    output logic [6:0] opcode,
    output logic [6:0] funct7,
    output logic [2:0] funct3
);

    // *************************************************************
    // ACCESSING INSTRUCTION MEMORY

    localparam REG_WIDTH = 17; // {opcode, funct7, funct3}

    logic [REG_WIDTH - 1: 0] data;
    logic isInst, ascii_in_range;

    get_inst #(.REG_WIDTH(REG_WIDTH)) _get_inst (
        .compressed_inst(compressed_inst),
        .data(data),
        .isInst(isInst)
    ); 

    assign opcode = data[16:10];
    assign funct7 = data[9:3];
    assign funct3 = data[2:0];

    compress_letters _get_compression ( 
        .incoming_ascii(incoming_ascii),
        .compressed_ascii(compressed_ascii),
        .is_in_range(ascii_in_range)
    );

    // *************************************************************

    typedef enum {
        IDLE, 
        BUSY,
        RETURN,
        ERROR
    } state_t state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);
    assign busy_flag = (state != IDLE);

    logic [4:0] [4:0] compressed_buffer;

    always_ff @(posedge clk_in) begin
        
        if (valid_data && !rst_in) begin
            if (new_character) begin
                case (state) 
                    IDLE: if (ascii_in_range) begin
                        state <= ACCUMULATING;
                        compressed_buffer <= {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED__, compressed_ascii};
                    end BUSY: begin
                        if (ascii_in_range) compressed_buffer <= {compressed_buffer[3:0], compressed_ascii}; 
                        else state <= ((incoming_ascii == " " || incoming_ascii == ",") && isInst) ? RETURN : ERROR;
                    end RETURN : state <= IDLE;
                endcase
            end
        end else state <= IDLE;
    end

endmodule // instruction_interpreter

module get_inst #(
    parameter REG_WIDTH 
    )(
    input wire [4:0][4:0] compressed_inst,
    output wire [REG_WIDTH - 1:0] data,
    output wire isInst
);

    assign isInst = (data != 0);

    always_comb begin
        case (compressed_inst)
            {COMPRESSED__, COMPRESSED__, COMPRESSED_A, COMPRESSED_D, COMPRESSED_D} : data = {OP_REG, 7'b0000000, F3_ADD_SUB}; // add
            {COMPRESSED__, COMPRESSED_A, COMPRESSED_D, COMPRESSED_D, COMPRESSED_I} : data = {OP_IMM, 7'b1111111, F3_ADD_SUB}; // addi
            {COMPRESSED__, COMPRESSED__, COMPRESSED_A, COMPRESSED_N, COMPRESSED_D} : data = {OP_REG, 7'b0000000, F3_AND}; // and
            {COMPRESSED__, COMPRESSED_A, COMPRESSED_N, COMPRESSED_D, COMPRESSED_I} : data = {OP_IMM, 7'b1111111, F3_AND}; // andi
            {COMPRESSED_A, COMPRESSED_U, COMPRESSED_I, COMPRESSED_P, COMPRESSED_C} : data = {OP_AUIPC, 7'b0000000, 3'b000}; // auipc
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_E, COMPRESSED_Q} : data = {OP_BRANCH, 7'b0000000, F3_BEQ}; // beq
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_G, COMPRESSED_E} : data = {OP_BRANCH, 7'b0000000, F3_BGE}; // bge
            {COMPRESSED__, COMPRESSED_B, COMPRESSED_G, COMPRESSED_E, COMPRESSED_U} : data = {OP_BRANCH, 7'b0000000, F3_BGEU}; // bgeu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_L, COMPRESSED_T} : data = {OP_BRANCH, 7'b0000000, F3_BLT}; // blt
            {COMPRESSED__, COMPRESSED_B, COMPRESSED_L, COMPRESSED_T, COMPRESSED_U} : data = {OP_BRANCH, 7'b0000000, F3_BLTU}; // bltu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_N, COMPRESSED_E} : data = {OP_BRANCH, 7'b0000000, F3_BNE}; // bne
            {COMPRESSED__, COMPRESSED__, COMPRESSED_J, COMPRESSED_A, COMPRESSED_L} : data = {OP_JAL, 7'b0000000, F3_ADD_SUB}; // jal
            {COMPRESSED__, COMPRESSED_J, COMPRESSED_A, COMPRESSED_L, COMPRESSED_R} : data = {OP_JALR, 7'b0000000, F3_ADD_SUB}; // jalr
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_B} : data = {OP_LOAD, 7'b0000000, F3_LB}; // lb
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_B, COMPRESSED_U} : data = {OP_LOAD, 7'b0000000, F3_LBU}; // lbu
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_H} : data = {OP_LOAD, 7'b0000000, F3_LH}; // lh
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_H, COMPRESSED_U} : data = {OP_LOAD, 7'b0000000, F3_LHU}; // lhu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_U, COMPRESSED_I} : data = {OP_LUI, 7'b0000000, 3'b000}; // lui
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_W} : data = {OP_LOAD, 7'b0000000, F3_LW}; // lw
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_O, COMPRESSED_R} : data = {OP_REG, 7'b0000000, F3_OR}; // or
            {COMPRESSED__, COMPRESSED__, COMPRESSED_O, COMPRESSED_R, COMPRESSED_I} : data = {OP_IMM, 7'b1111111, F3_OR}; // ori
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_L} : data = {OP_REG, 7'b0000000, F3_SLL}; // sll
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_L, COMPRESSED_I} : data = {OP_IMM, 7'b0100000, F3_SLL}; // slli
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T} : data = {OP_REG, 7'b0000000, F3_SLT}; // slt
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_I} : data = {OP_IMM, 7'b1111111, F3_SLT}; // slti
            {COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_I, COMPRESSED_U} : data = {OP_IMM, 7'b1111111, F3_SLTU}; // sltiu
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_U} : data = {OP_REG, 7'b0000000, F3_SLTU}; // sltu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_A} : data = {OP_REG, 7'b0100000, F3_SRL_SRA}; // sra
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_A, COMPRESSED_I} : data = {OP_IMM, 7'b0100000, F3_SRL_SRA}; // srai
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_L} : data = {OP_REG, 7'b0000000, F3_SRL_SRA}; // srl
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_L, COMPRESSED_I} : data = {OP_IMM, 7'b0000000, F3_SRL_SRA}; // srli
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_B} : data = {OP_STORE, 7'b0000000, F3_SB}; // sb
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_H} : data = {OP_STORE, 7'b0000000, F3_SH}; // sh
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_U, COMPRESSED_B} : data = {OP_REG, 7'b0100000, F3_ADD_SUB}; // sub
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_W} : data = {OP_STORE, 7'b0000000, F3_SW}; // sw
            {COMPRESSED__, COMPRESSED__, COMPRESSED_X, COMPRESSED_O, COMPRESSED_R} : data = {OP_REG, 7'b0000000, F3_XOR}; // xor
            {COMPRESSED__, COMPRESSED_X, COMPRESSED_O, COMPRESSED_R, COMPRESSED_I} : data = {OP_IMM, 7'b1111111, F3_XOR}; // xori
            default                                                                : data = 0; // no inst
        endcase
    end

endmodule

module compress_letters ( 
    input wire [7:0] incoming_ascii,
    output logic [4:0] compressed_ascii,
    output logic is_in_range
    );

    assign is_in_range = (compressed_ascii != 5'h1f);

    always_comb begin
        case (incoming_ascii)
            "a", "A" : compressed_ascii = COMPRESSED_A;
            "b", "B" : compressed_ascii = COMPRESSED_B;
            "c", "C" : compressed_ascii = COMPRESSED_C;
            "d", "D" : compressed_ascii = COMPRESSED_D;
            "e", "E" : compressed_ascii = COMPRESSED_E;
            "g", "G" : compressed_ascii = COMPRESSED_G;
            "h", "H" : compressed_ascii = COMPRESSED_H;
            "i", "I" : compressed_ascii = COMPRESSED_I;
            "j", "J" : compressed_ascii = COMPRESSED_J;
            "l", "L" : compressed_ascii = COMPRESSED_L;
            "n", "N" : compressed_ascii = COMPRESSED_N;
            "o", "O" : compressed_ascii = COMPRESSED_O;
            "p", "P" : compressed_ascii = COMPRESSED_P;
            "q", "Q" : compressed_ascii = COMPRESSED_Q;
            "r", "R" : compressed_ascii = COMPRESSED_R;
            "s", "S" : compressed_ascii = COMPRESSED_S;
            "t", "T" : compressed_ascii = COMPRESSED_T;
            "u", "U" : compressed_ascii = COMPRESSED_U;
            "w", "W" : compressed_ascii = COMPRESSED_W;
            "x", "X" : compressed_ascii = COMPRESSED_X;
            default  : compressed_ascii = 5'h1f;
        endcase
    end
        
endmodule

`default_nettype wire