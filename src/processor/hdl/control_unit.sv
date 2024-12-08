module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input logic [31:0] imm,
    output logic       reg_write,
    output logic       mem_to_reg,
    output logic       mem_read,
    output logic       mem_write,
    output logic       alu_src,
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_ctrl
);

always_comb begin
        reg_write = 1'b0;
        mem_to_reg = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        alu_src = 1'b0;
        jump = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src = 1'b1;
            end
            7'b0000011: begin // LOAD
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_to_reg = 1'b1;
                mem_read = 1'b1;
            end
            7'b0100011: begin // STORE
                mem_write = 1'b1;
                alu_src = 1'b1;
            end
            7'b1100011: begin // BRANCH
                branch = 1'b1;
            end
            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump = 1'b1;
            end
            7'b1100111: begin // JALR
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 1'b1;
            end
            7'b0110111: begin // LUI
                reg_write = 1'b1;
                // alu_src = 1'b1;    // Use immediate
                // alu_ctrl = 4'b1010; // New ALU op for LUI
                // lui_enable = 1'b1;
               
        end
        7'b0010111: begin // AUIPC
            reg_write = 1'b1;
            // alu_src = 1'b1;    // Use immediate
            // alu_ctrl = 4'b1011; // New ALU op for AUIPC
        end 
        endcase
    end

    // ALU control
    always_comb begin
        case (opcode)
            7'b0110011: begin // R-type, I TYPE 
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b001: alu_ctrl = 4'b0101; //sll
                    3'b101: alu_ctrl = funct7[5] ? 4'b0111 : 4'b0110; //sra(funct7:2):srl
                    3'b010: alu_ctrl = 4'b1000; //slt
                    3'b011: alu_ctrl = 4'b1001; //sltu
                   

                    default: alu_ctrl = 4'b0000;
                endcase
            end
            7'b0010011: begin // I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADD
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b001: alu_ctrl = 4'b0101; // SLL
                    3'b101: alu_ctrl = imm[5] ? 4'b0111 : 4'b0110; //sra(funct7:2):srl //SOOO the thing is this is just based on imm 11:5 and the rest is 4:0
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    3'b011: alu_ctrl = 4'b1001; // SLTU
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            7'b0010111: begin // AUIPC
                alu_ctrl = 4'b1011; // New ALU op for AUIPC
            end
            7'b0110111: begin // LUI
                alu_ctrl = 4'b1010; // New ALU op for LUI
            end


            default: begin end 
        endcase
    end
endmodule