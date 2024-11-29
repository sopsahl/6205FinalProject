package riscv_constants;
    // Instruction field positions
    parameter OPCODE_POS  = 6;   // inst[6:0]
    parameter RD_POS      = 11;  // inst[11:7]
    parameter FUNCT3_POS  = 14;  // inst[14:12]
    parameter RS1_POS     = 19;  // inst[19:15]
    parameter RS2_POS     = 24;  // inst[24:20]
    parameter FUNCT7_POS  = 31;  // inst[31:25]

    // Field widths
    parameter OPCODE_WIDTH = 7;
    parameter RD_WIDTH     = 5;
    parameter FUNCT3_WIDTH = 3;
    parameter RS1_WIDTH    = 5;
    parameter RS2_WIDTH    = 5;
    parameter FUNCT7_WIDTH = 7;

    // Opcodes
    parameter logic [6:0] OP_REG      = 7'b0110011;  // R-type
    parameter logic [6:0] OP_IMM      = 7'b0010011;  // I-type arithmetic
    parameter logic [6:0] OP_LOAD     = 7'b0000011;  // Loads
    parameter logic [6:0] OP_STORE    = 7'b0100011;  // Stores
    parameter logic [6:0] OP_BRANCH   = 7'b1100011;  // Branches
    parameter logic [6:0] OP_JAL      = 7'b1101111;  // Jump and Link
    parameter logic [6:0] OP_JALR     = 7'b1100111;  // Jump and Link Register
    parameter logic [6:0] OP_LUI      = 7'b0110111;  // Load Upper Immediate
    parameter logic [6:0] OP_AUIPC    = 7'b0010111;  // Add Upper Immediate to PC
    parameter logic [6:0] OP_SYSTEM   = 7'b1110011;  // System calls

    // FUNCT3 values
    // Arithmetic/Logic
    parameter logic [2:0] F3_ADD_SUB  = 3'b000;  // ADD/SUB
    parameter logic [2:0] F3_XOR      = 3'b100;  // XOR
    parameter logic [2:0] F3_OR       = 3'b110;  // OR
    parameter logic [2:0] F3_AND      = 3'b111;  // AND
    parameter logic [2:0] F3_SLL      = 3'b001;  // Shift Left Logical
    parameter logic [2:0] F3_SRL_SRA  = 3'b101;  // Shift Right Logical/Arithmetic
    parameter logic [2:0] F3_SLT      = 3'b010;  // Set Less Than
    parameter logic [2:0] F3_SLTU     = 3'b011;  // Set Less Than Unsigned

    // Loads
    parameter logic [2:0] F3_LB       = 3'b000;  // Load Byte
    parameter logic [2:0] F3_LH       = 3'b001;  // Load Halfword
    parameter logic [2:0] F3_LW       = 3'b010;  // Load Word
    parameter logic [2:0] F3_LBU      = 3'b100;  // Load Byte Unsigned
    parameter logic [2:0] F3_LHU      = 3'b101;  // Load Halfword Unsigned

    // Stores
    parameter logic [2:0] F3_SB       = 3'b000;  // Store Byte
    parameter logic [2:0] F3_SH       = 3'b001;  // Store Halfword
    parameter logic [2:0] F3_SW       = 3'b010;  // Store Word

    // Branches
    parameter logic [2:0] F3_BEQ      = 3'b000;  // Branch Equal
    parameter logic [2:0] F3_BNE      = 3'b001;  // Branch Not Equal
    parameter logic [2:0] F3_BLT      = 3'b100;  // Branch Less Than
    parameter logic [2:0] F3_BGE      = 3'b101;  // Branch Greater or Equal
    parameter logic [2:0] F3_BLTU     = 3'b110;  // Branch Less Than Unsigned
    parameter logic [2:0] F3_BGEU     = 3'b111;  // Branch Greater or Equal Unsigned

    // FUNCT7 values
    parameter logic [6:0] F7_ADD      = 7'b0000000;  // ADD
    parameter logic [6:0] F7_SUB      = 7'b0100000;  // SUB
    parameter logic [6:0] F7_SRL      = 7'b0000000;  // Shift Right Logical
    parameter logic [6:0] F7_SRA      = 7'b0100000;  // Shift Right Arithmetic
    typedef struct {
        bit [6:0]  opcode;
        bit [2:0]  funct3;
        bit [6:0]  funct7;
        bit [4:0]  funct5;
        bit [1:0]  funct2;
        bit [4:0]  rd;
        bit [4:0]  rs1;
        bit [4:0]  rs2;
        bit [4:0]  rs3;
        bit [31:0] immI;
        bit [31:0] immS;
        bit [31:0] immB;
        bit [31:0] immU;
        bit [31:0] immJ;
        bit [11:0] csr;
} InstFields;
function logic [31:0] generate_imm(input logic [31:0] instruction, input logic [6:0] opcode);
    logic [31:0] imm;
    case (opcode)
        7'b0010011, 7'b0000011, 7'b1100111: // I-type
            imm = {{20{instruction[31]}}, instruction[31:20]};
        7'b0100011: // S-type
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        7'b1100011: // B-type
            imm = {{19{instruction[31]}}, instruction[31], instruction[7], 
                  instruction[30:25], instruction[11:8], 1'b0};
        7'b0110111, 7'b0010111: // U-type
            imm = {instruction[31:12], 12'b0};
        7'b1101111: // J-type
            imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                  instruction[20], instruction[30:21], 1'b0};
        default: imm = 32'b0;
    endcase
    return imm;
endfunction
    

endpackage