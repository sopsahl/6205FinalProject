// Copyright Computer Structure Group, MIT 2018

package riscv_constants;

    // Opcode Fields
    
    typedef struct packed {
        bit [6:0] opcode;
        bit [2:0] funct3;
        bit [6:0] funct7;
        bit [4:0] funct5;
        bit [1:0] funct2;
        bit [4:0] rd;
        bit [4:0] rs1;
        bit [4:0] rs2;
        bit [4:0] rs3;
        bit [31:0] immI;
        bit [31:0] immS;
        bit [31:0] immB;
        bit [31:0] immU;
        bit [31:0] immJ;
        bit [11:0] csr;
    } InstFields;

    // Function to extract instruction fields
    function InstFields getInstFields(bit [31:0] inst);
        InstFields fields;
        fields.opcode = inst[6:0];
        fields.funct3 = inst[14:12];
        fields.funct7 = inst[31:25];
        fields.funct5 = inst[31:27];
        fields.funct2 = inst[26:25];
        fields.rd     = inst[11:7];
        fields.rs1    = inst[19:15];
        fields.rs2    = inst[24:20];
        fields.rs3    = inst[31:27];
        fields.immI   = { {20{inst[31]}}, inst[31:20] };
        fields.immS   = { {20{inst[31]}}, inst[31:25], inst[11:7] };
        fields.immB   = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
        fields.immU   = { inst[31:12], 12'b0 };
        fields.immJ   = { {11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };
        fields.csr     = inst[31:20];
        return fields;
    endfunction

    // Opcode Definitions
    parameter bit [6:0] OP_LOAD     = 7'b0000011;
    parameter bit [6:0] OP_LOADFP   = 7'b0000111;
    parameter bit [6:0] OP_MISCMEM  = 7'b0001111;
    parameter bit [6:0] OP_OPIMM    = 7'b0010011;
    parameter bit [6:0] OP_AUIPC    = 7'b0010111;
    parameter bit [6:0] OP_OPIMM32  = 7'b0011011;
    parameter bit [6:0] OP_STORE    = 7'b0100011;
    parameter bit [6:0] OP_STOREFP  = 7'b0100111;
    parameter bit [6:0] OP_OP       = 7'b0110011;
    parameter bit [6:0] OP_LUI      = 7'b0110111;
    parameter bit [6:0] OP_OP32     = 7'b0111011;

    parameter bit [6:0] OP_BRANCH   = 7'b1100011;
    parameter bit [6:0] OP_JALR     = 7'b1100111;
    parameter bit [6:0] OP_JAL      = 7'b1101111;

    // 5-bit Opcode Fields
    parameter bit [4:0] OP5_LOAD     = 5'b00000;
    parameter bit [4:0] OP5_LOADFP   = 5'b00001;
    parameter bit [4:0] OP5_MISCMEM  = 5'b00011;
    parameter bit [4:0] OP5_OPIMM    = 5'b00100;
    parameter bit [4:0] OP5_AUIPC    = 5'b00101;
    parameter bit [4:0] OP5_OPIMM32  = 5'b00110;
    parameter bit [4:0] OP5_STORE    = 5'b01000;
    parameter bit [4:0] OP5_STOREFP  = 5'b01001;
    parameter bit [4:0] OP5_AMO      = 5'b01011;
    parameter bit [4:0] OP5_OP       = 5'b01100;
    parameter bit [4:0] OP5_LUI      = 5'b01101;
    parameter bit [4:0] OP5_OP32     = 5'b01110;
    parameter bit [4:0] OP5_MADD     = 5'b10000;
    parameter bit [4:0] OP5_MSUB     = 5'b10001;
    parameter bit [4:0] OP5_NMSUB    = 5'b10010;
    parameter bit [4:0] OP5_NMADD    = 5'b10011;
    parameter bit [4:0] OP5_OPFP     = 5'b10100;
    parameter bit [4:0] OP5_BRANCH   = 5'b11000;
    parameter bit [4:0] OP5_JALR     = 5'b11001;
    parameter bit [4:0] OP5_JAL      = 5'b11011;
    parameter bit [4:0] OP5_SYSTEM   = 5'b11100;

    // Func3 Fields
    // For BRANCH opcode
    parameter bit [2:0] FN3_BEQ   = 3'b000;
    parameter bit [2:0] FN3_BNE   = 3'b001;
    parameter bit [2:0] FN3_BLT   = 3'b100;
    parameter bit [2:0] FN3_BGE   = 3'b101;
    parameter bit [2:0] FN3_BLTU  = 3'b110;
    parameter bit [2:0] FN3_BGEU  = 3'b111;

    // For LOAD, STORE, and AMO opcodes
    parameter bit [2:0] FN3_B     = 3'b000;
    parameter bit [2:0] FN3_H     = 3'b001;
    parameter bit [2:0] FN3_W     = 3'b010;
    parameter bit [2:0] FN3_D     = 3'b011;
    parameter bit [2:0] FN3_BU    = 3'b100;
    parameter bit [2:0] FN3_HU    = 3'b101;
    parameter bit [2:0] FN3_WU    = 3'b110;

    // For OP, OPIMM, OP32, OPIMM32 opcodes
    parameter bit [2:0] FN3_ADDSUB = 3'b000;
    parameter bit [2:0] FN3_SLL    = 3'b001;
    parameter bit [2:0] FN3_SLT    = 3'b010;
    parameter bit [2:0] FN3_SLTU   = 3'b011;
    parameter bit [2:0] FN3_XOR    = 3'b100;
    parameter bit [2:0] FN3_SR     = 3'b101;
    parameter bit [2:0] FN3_OR     = 3'b110;
    parameter bit [2:0] FN3_AND    = 3'b111;


    // Function to check if an instruction is legal
    function bit isLegalInstruction(bit [31:0] inst);
        InstFields fields = getInstFields(inst);
        case (fields.opcode)
            OP_LOAD: begin
                case (fields.funct3)
                    FN3_B, FN3_H, FN3_W, FN3_BU, FN3_HU: return 1'b1;
                    default: return 1'b0;
                endcase
            end
            OP_OPIMM: begin
                case (fields.funct3)
                    FN3_ADDSUB, FN3_SLT, FN3_SLTU, FN3_XOR, FN3_OR, FN3_AND: return 1'b1;
                    FN3_SLL: return (fields.funct7[6:1] == 6'b000000) && (fields.funct7[0] == 1'b0);
                    FN3_SR:  return ((fields.funct7[6:1] == 6'b000000) || (fields.funct7[6:1] == 6'b010000)) && (fields.funct7[0] == 1'b0);
                    default: return 1'b0;
                endcase
            end
            OP_AUIPC: return 1'b1;
            OP_STORE: begin
                case (fields.funct3)
                    FN3_B, FN3_H, FN3_W: return 1'b1;
                    default: return 1'b0;
                endcase
            end
            OP_OP: begin
                case (fields.funct3)
                    FN3_ADDSUB, FN3_SR: return (fields.funct7 == 7'b0000000) || (fields.funct7 == 7'b0100000);
                    FN3_SLL, FN3_SLT, FN3_SLTU, FN3_XOR, FN3_OR, FN3_AND: return (fields.funct7 == 7'b0000000);
                    default: return 1'b0;
                endcase
            end
            OP_LUI: return 1'b1;
            OP_BRANCH: begin
                case (fields.funct3)
                    FN3_BEQ, FN3_BNE, FN3_BLT, FN3_BGE, FN3_BLTU, FN3_BGEU: return 1'b1;
                    default: return 1'b0;
                endcase
            end
            OP_JALR: return (fields.funct3 == 3'b000);
            OP_JAL: return 1'b1;
            
            default: return 1'b0;
        endcase
    endfunction

    // Immediate Types
    typedef enum logic [2:0] {
        ImmI,
        ImmS,
        ImmB,
        ImmU,
        ImmJ
    } ImmediateType;

    // Maybe Type for ImmediateType
    typedef struct packed {
        bit valid;
        ImmediateType value;
    } Maybe_ImmediateType;
    typedef enum logic [2:0]{
        R_type,
        I_type,
        S_type,
        B_type,
        U_type,
        J_type,
    } InstructionType;

    // Function to get Immediate Type from Instruction
    function Maybe_ImmediateType getImmediateTypeFrom32BitInst(bit [31:0] inst);
        InstantiateInstFields fields = getInstFields(inst);
        case (inst[6:2])
            OP5_LOAD, OP5_LOADFP, OP5_OPIMM, OP5_OPIMM32, OP5_JALR: begin
                Maybe_ImmediateType m;
                m.valid = 1'b1;
                m.value = ImmI;
                return m;
            end
            OP5_AUIPC, OP5_LUI: begin
                Maybe_ImmediateType m;
                m.valid = 1'b1;
                m.value = ImmU;
                return m;
            end
            OP5_STORE, OP5_STOREFP: begin
                Maybe_ImmediateType m;
                m.valid = 1'b1;
                m.value = ImmS;
                return m;
            end
            OP5_BRANCH: begin
                Maybe_ImmediateType m;
                m.valid = 1'b1;
                m.value = ImmB;
                return m;
            end
            OP5_JAL: begin
                Maybe_ImmediateType m;
                m.valid = 1'b1;
                m.value = ImmJ;
                return m;
            end
            default: begin
                Maybe_ImmediateType m;
                m.valid = 1'b0;
                return m;
            end
        endcase
    endfunction

    // Function to get Immediate value based on Decoded Instruction
    typedef struct {
        bit legal;
        bit valid_rs1;
        bit valid_rs2;
        bit valid_rd;
        Maybe_ImmediateType immediateType;
        bit [31:0] inst;
    } DecodedInst;

    function bit [31:0] getImmediate(bit [31:0] inst);
        DecodedInst dInst;
        dInst = decodeInst(inst);
        case (dInst.immediateType.value)
            ImmI: return getImmediateI(inst);
            ImmS: return getImmediateS(inst);
            ImmB: return getImmediateB(inst);
            ImmU: return getImmediateU(inst);
            ImmJ: return getImmediateJ(inst);
            default: return 32'b0;
        endcase
    endfunction

    // Function to decode instruction
    function DecodedInst decodeInst(bit [31:0] input_inst);
        DecodedInst dInst;
        dInst.legal = isLegalInstruction(input_inst);
        dInst.valid_rs1 = usesRS1(input_inst);
        dInst.valid_rs2 = usesRS2(input_inst);
        dInst.valid_rd  = usesRD(input_inst);
        dInst.immediateType = getImmediateTypeFrom32BitInst(input_inst);
        dInst.inst = input_inst;
        return dInst;
    endfunction

    // Functions to extract immediates
    function bit [31:0] getImmediateI(bit [31:0] inst);
        return { {20{inst[31]}}, inst[31:20] };
    endfunction

    function bit [31:0] getImmediateS(bit [31:0] inst);
        return { {20{inst[31]}}, inst[31:25], inst[11:7] };
    endfunction

    function bit [31:0] getImmediateB(bit [31:0] inst);
        return { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
    endfunction

    function bit [31:0] getImmediateU(bit [31:0] inst);
        return { inst[31:12], 12'b0 };
    endfunction

    function bit [31:0] getImmediateJ(bit [31:0] inst);
        return { {11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };
    endfunction

    // Functions to determine usage of registers
    function bit usesRD(bit [31:0] inst);
        case (inst[6:2])
            5'b01101: return 1'b1; // LUI
            5'b11011: return 1'b1; // JAL
            5'b00000: return 1'b1; // LH, LD, LW, LWU, LBU, LHU, LB
            5'b01100: return 1'b1; // SLL, MULH, SLTU, MULHU, SLT, MULHSU, OR, REM, XOR, DIV, AND, REMU, SRL, DIVU, SRA, ADD, MUL, SUB
            5'b11001: return 1'b1; // JALR
            5'b00100: return 1'b1; // SRLI, SRAI, SLLI, ORI, SLTIU, ANDI, SLTI, ADDI, XORI
            5'b00101: return 1'b1; // AUIPC
            default: return 1'b0;
        endcase
    endfunction

    function bit usesRS1(bit [31:0] inst);
        case (inst[6:2])
            5'b11000: return 1'b1; // BGE, BNE, BLTU, BLT, BGEU, BEQ
            5'b00000: return 1'b1; // LH, LD, LW, LWU, LBU, LHU, LB
            5'b01000: return 1'b1; // SH, SB, SW, SD
            5'b01100: return 1'b1; // SLL, MULH, SLTU, MULHU, SLT, MULHSU, OR, REM, XOR, DIV, AND, REMU, SRL, DIVU, SRA, ADD, MUL, SUB
            5'b11001: return 1'b1; // JALR
            5'b00100: return 1'b1; // SRLI, SRAI, SLLI, ORI, SLTIU, ANDI, SLTI, ADDI, XORI
            default: return 1'b0;
        endcase
    endfunction

    function bit usesRS2(bit [31:0] inst);
        case (inst[6:2])
            5'b11000: return 1'b1; // BGE, BNE, BLTU, BLT, BGEU, BEQ
            5'b01000: return 1'b1; // SH, SB, SW, SD
            5'b01100: return 1'b1; // SLL, MULH, SLTU, MULHU, SLT, MULHSU, OR, REM, XOR, DIV, AND, REMU, SRL, DIVU, SRA, ADD, MUL, SUB
            default: return 1'b0;
        endcase
    endfunction

    // Function to execute ALU operations for 32-bit instructions
    function bit [31:0] execALU32(bit [31:0] inst, bit [31:0] rs1_val, bit [31:0] rs2_val, bit [31:0] imm_val, bit [31:0] pc);
        bit isLUI = inst[2] == 1'b1 && inst[5] == 1'b1;
        bit isAUIPC = inst[2] == 1'b1 && inst[5] == 1'b0;
        bit isIMM = inst[5] == 1'b0;
        bit [31:0] rd_val = 32'b0;

        if (isLUI) begin
            rd_val = imm_val;
        end else if (isAUIPC) begin
            rd_val = pc + imm_val;
        end else begin
            bit [31:0] alu_src1 = rs1_val;
            bit [31:0] alu_src2 = isIMM ? imm_val : rs2_val;
            bit [2:0] funct3 = inst[14:12];
            bit inst_30 = inst[30];
            
            if ((funct3 == FN3_ADDSUB) && isIMM) begin
                // Special case for ADDI
                inst_30 = 1'b0;
            end
            rd_val = alu32(funct3, inst_30, alu_src1, alu_src2);
        end

        return rd_val;
    endfunction

    // ALU Function
    function bit [31:0] alu32(bit [2:0] funct3, bit inst_30, bit [31:0] a, bit [31:0] b);
        bit isSRA = (funct3 == FN3_SR) && (inst_30 == 1'b1);
        bit [4:0] shamt = b[4:0];
        bit [31:0] res;

        case (funct3)
            FN3_ADDSUB: res = (inst_30) ? (a - b) : (a + b);
            FN3_SLL:    res = a << shamt;
            FN3_SLT:    res = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            FN3_SLTU:   res = (a < b) ? 32'b1 : 32'b0;
            FN3_XOR:    res = a ^ b;
            FN3_SR:     res = isSRA ? ($signed(a) >>> shamt) : (a >> shamt);
            FN3_OR:     res = a | b;
            FN3_AND:    res = a & b;
            default:    res = 32'b0;
        endcase

        return res;
    endfunction

    // Control Result Structure
    typedef struct packed {
        bit taken;
        bit [31:0] nextPC;
    } ControlResult;

    // Function to execute control operations
    function ControlResult execControl32(bit [31:0] inst, bit [31:0] rs1_val, bit [31:0] rs2_val, bit [31:0] imm_val, bit [31:0] pc);
        bit isControl = (inst[6:4] == 3'b110);
        bit isJAL    = (inst[2] == 1'b1) && (inst[3] == 1'b1);
        bit isJALR   = (inst[2] == 1'b1) && (inst[3] == 1'b0);

        bit [31:0] incPC = pc + 32'd4;
        bit [2:0]  funct3 = inst[14:12];
        ControlResult result;
        result.taken = 1'b1; // Default to taken for JAL and JALR
        result.nextPC = incPC;
        bit [31:0] rd_val = pc; // For JAL and JALR

        if (!isControl) begin
            // Not a control instruction
            result.taken = 1'b0;
            result.nextPC = incPC;
        end else if (isJAL) begin
            result.taken = 1'b1;
            result.nextPC = pc + imm_val;
        end else if (isJALR) begin
            result.taken = 1'b1;
            result.nextPC = (rs1_val + imm_val) & ~32'b1; // Zero out LSB
        end else begin
            // Branch
            bit branch_taken;
            case (funct3)
                FN3_BEQ:  branch_taken = (rs1_val == rs2_val);
                FN3_BNE:  branch_taken = (rs1_val != rs2_val);
                FN3_BLT:  branch_taken = ($signed(rs1_val) < $signed(rs2_val));
                FN3_BGE:  branch_taken = ($signed(rs1_val) >= $signed(rs2_val));
                FN3_BLTU: branch_taken = (rs1_val < rs2_val);
                FN3_BGEU: branch_taken = (rs1_val >= rs2_val);
                default: branch_taken = 1'b0;
            endcase

            result.taken = branch_taken;
            if (branch_taken)
                result.nextPC = pc + imm_val;
            else
                result.nextPC = incPC;
        end

        return result;
    endfunction

    // Instruction Classes
    function bit isMemoryInst(DecodedInst dInst);
        return (dInst.inst[6] == 1'b0) && (dInst.inst[4:3] == 2'b00);
    endfunction

    function bit isControlInst(DecodedInst dInst);
        return (dInst.inst[6:4] == 3'b110); // This also covers a reserved opcode
    endfunction

endpackage