module branch_unit (
    input  logic        branch,       // Branch control signal
    input  logic [2:0]  funct3,       // Function code to determine branch type
    input  logic [31:0] rs1_val,      // Value of source register 1
    input  logic [31:0] rs2_val,      // Value of source register 2
    output logic        branch_taken  // Output signal indicating if branch is taken
);

    always_comb begin
        branch_taken = 1'b0;
        
        if (branch) begin
            case (funct3)
                3'b000: branch_taken = (rs1_val == rs2_val);              // BEQ
                3'b001: branch_taken = (rs1_val != rs2_val);              // BNE
                3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val));   // BLT
                3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));  // BGE
                3'b110: branch_taken = (rs1_val < rs2_val);               // BLTU
                3'b111: branch_taken = (rs1_val >= rs2_val);              // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end

endmodule