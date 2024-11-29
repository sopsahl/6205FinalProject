module ALU (
    input  logic [31:0] rs1_val,
    input  logic [31:0] rs2_val,
    input  logic [31:0] imm,
    input  logic [31:0] pc,
    input  logic [3:0]  alu_ctrl,
    input  logic        alu_src,
    output logic [31:0] alu_result
);
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
            4'b1011: alu_result = pc + imm; // AUIPC
            default: alu_result = rs1_val + (alu_src ? imm : rs2_val);
        endcase
    end
endmodule