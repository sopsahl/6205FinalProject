module RegisterFile (
    input  logic         clk,
    input  logic         rst,
    input  logic         we,     // Write enable
    input  logic [4:0]   rs1,    // Source register 1
    input  logic [4:0]   rs2,    // Source register 2
    input  logic [4:0]   rd,     // Destination register
    input  logic [31:0]  wd,     // Write data
    output logic [31:0]  rd1,    // Read data 1
    output logic [31:0]  rd2     // Read data 2
);
    logic [31:0][31:0] registers;

    // Read ports
    assign rd1 = (rs1 != 0) ? registers[rs1] : 32'd0;
    assign rd2 = (rs2 != 0) ? registers[rs2] : 32'd0;

    // Write por
    always_ff @(posedge clk) begin
        if (rst) begin
            registers <= 32'd0;
        end else if (we && (rd != 0)) begin
            registers[rd] <= wd;
        end
    end
endmodule