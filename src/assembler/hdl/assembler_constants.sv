
package assembler_constants;

    // Instruction Fields
    typedef struct packed {
        bit [6:0] opcode;
        bit [2:0] funct3;
        bit [6:0] funct7;
        bit [4:0] rd;
        bit [4:0] rs1;
        bit [4:0] rs2;
        bit [31:0] imm;
    } InstFields;

    typedef enum {
        IDLE,
        PC_MAPPING,
        INSTRUCTION_MAPPING,
        ERROR
    } assembler_state;

    // Compressed ASCII Values
        parameter logic [4:0] COMPRESSED__ = 5'h00;
        parameter logic [4:0] COMPRESSED_A = 5'h01;
        parameter logic [4:0] COMPRESSED_B = 5'h02;
        parameter logic [4:0] COMPRESSED_C = 5'h03;
        parameter logic [4:0] COMPRESSED_D = 5'h04;
        parameter logic [4:0] COMPRESSED_E = 5'h05;
        parameter logic [4:0] COMPRESSED_G = 5'h06;
        parameter logic [4:0] COMPRESSED_H = 5'h07;
        parameter logic [4:0] COMPRESSED_I = 5'h08;
        parameter logic [4:0] COMPRESSED_J = 5'h09;
        parameter logic [4:0] COMPRESSED_L = 5'h0a;
        parameter logic [4:0] COMPRESSED_N = 5'h0b;
        parameter logic [4:0] COMPRESSED_O = 5'h0c;
        parameter logic [4:0] COMPRESSED_P = 5'h0d;
        parameter logic [4:0] COMPRESSED_Q = 5'h0e;
        parameter logic [4:0] COMPRESSED_R = 5'h0f;
        parameter logic [4:0] COMPRESSED_S = 5'h10;
        parameter logic [4:0] COMPRESSED_T = 5'h11;
        parameter logic [4:0] COMPRESSED_U = 5'h12;
        parameter logic [4:0] COMPRESSED_W = 5'h13;
        parameter logic [4:0] COMPRESSED_X = 5'h14;
    
    // OPCODEs
        parameter logic [6:0] OP_REG      = 7'b0110011;  // R-type
        parameter logic [6:0] OP_IMM      = 7'b0010011;  // I-type arithmetic
        parameter logic [6:0] OP_LOAD     = 7'b0000011;  // Loads
        parameter logic [6:0] OP_STORE    = 7'b0100011;  // Stores
        parameter logic [6:0] OP_BRANCH   = 7'b1100011;  // Branches
        parameter logic [6:0] OP_JAL      = 7'b1101111;  // Jump and Link
        parameter logic [6:0] OP_JALR     = 7'b1100111;  // Jump and Link Register
        parameter logic [6:0] OP_LUI      = 7'b0110111;  // Load Upper Immediate
        parameter logic [6:0] OP_AUIPC    = 7'b0010111;  // Add Upper Immediate to PC

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
        parameter logic [6:0] F7_ADD      = 7'b0000000;  // ADD and Default
        parameter logic [6:0] F7_SUB      = 7'b0100000;  // SUB
        parameter logic [6:0] F7_SRL      = 7'b0000000;  // Shift Right Logical
        parameter logic [6:0] F7_SRA      = 7'b0100000;  // Shift Right Arithmetic
        parameter logic [6:0] F7_IMM      = 7'b1111111;  // IMMEDIATE f7 used in AND


    function logic isNum(byte ascii_char);
        return (ascii_char >= "0" && ascii_char <= "9");
    endfunction

    function logic isAlpha(byte ascii_char);
        return ((ascii_char >= "a" && ascii_char <= "f") || (ascii_char >= "A" && ascii_char <= "F"));
    endfunction

    function logic [3:0] ascii_to_hex(byte ascii_char);
        return (isNum(ascii_char)) ? ascii_char[3:0] : (isAlpha(ascii_char)) ? ascii_char[3:0] + 4'h9 : 4'h0;
    endfunction

    function logic [31:0] create_inst(InstFields inst);
        case (inst.opcode) 
            OP_REG : return {inst.funct7, inst.rs2, inst.rs1, inst.funct3, inst.rd, inst.opcode};
            OP_IMM : return {inst.imm[11:5] && inst.funct7, inst.imm[4:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
            OP_LOAD, OP_JALR : return {inst.imm[11:0], inst.rs1, inst.funct3, inst.rd, inst.opcode};
            OP_STORE : return {inst.imm[11:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:0], inst.opcode};
            OP_BRANCH : return {inst.imm[12], inst.imm[10:5], inst.rs2, inst.rs1, inst.funct3, inst.imm[4:1], inst.imm[11], inst.opcode};
            OP_LUI, OP_AUIPC : return {inst.imm[31:12], inst.rd, inst.opcode};
            OP_JAL : return {inst.imm[20], inst.imm[10:1], inst.imm[11], inst.imm[19:12], inst.rd, inst.opcode};
            default: return 32'b0;
        endcase
    endfunction


endpackage