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