`timescale 1ns / 1ps
`default_nettype none

// instruction_interpreter: takes the instruction (e.g. and, xor, ...)
// Up to 5 characters
// Calculates the corresponding instruction


import assembler_constants::*;


module instruction_interpreter #(
        parameter NUM_INSTRUCTIONS = 37,
    )(
    input wire clk_in,
    input wire rst_in,
    input wire valid_data,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,
    output logic busy_flag,

    output logic [6:0] opcode,
    output logic [6:0] funct7,
    output logic [2:0] funct3,
    output logic isSRAI 
);

    // *************************************************************
    // ACCESSING INSTRUCTION MEMORY

    localparam RAM_WIDTH = 18; // {opcode, funct7, funct3, isSRAI}

    logic [$clog2(NUM_INSTRUCTIONS) - 1: 0] address;
    logic [$clog2(RAM_WIDTH) - 1: 0] data;

    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(RAM_WIDTH),                      
        .RAM_DEPTH(NUM_INSTRUCTIONS),                
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Two Cycle Delay
        .INIT_FILE(`FPATH(data.mem))          // Location of the mappings in data/
    ) instruction_memory (
        .addra(address),     // Address bus, width determined from RAM_DEPTH
        .dina(),       // RAM input data, width determined from RAM_WIDTH
        .clka(clk_in),       // Clock
        .wea(1'b0),         // Write enable
        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1'b1),   // Output register enable
        .douta(data)      // RAM output data, width determined from RAM_WIDTH
    );

    assign opcode = data[17:11];
    assign funct7 = data[10:4];
    assign funct3 = data[3:1];
    assign isSRAI = data[0];

    logic isInst, ascii_in_range;

    get_address #(.NUM_INSTRUCTIONS(NUM_INSTRUCTIONS)) get_adr (
        .compressed_inst(compressed_inst),
        .address(address),
        .isInst(isInst)
    );

    compress_letters get_compression ( 
        .incoming_ascii(incoming_ascii),
        .compressed_ascii(compressed_ascii),
        .is_in_range(ascii_in_range)
    );

    // *************************************************************

    typedef enum {
        IDLE, 
        ACCUMULATING,
        FETCHING,
        RETURN,
        ERROR
    } state_t state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);
    assign busy_flag = (state != IDLE);

    logic [4:0] [4:0] compressed_buffer;

    always_ff @(posedge clk_in) begin
        
        if (valid_data && !rst_in) begin
            
            case (state) 
                IDLE: if (ascii_in_range) begin
                    state <= ACCUMULATING;
                    compressed_buffer <= {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED__, compressed_ascii};
                end ACCUMULATING: begin
                    if (ascii_in_range) compressed_buffer <= {compressed_buffer[3:0], compressed_ascii}; 
                    else state <= ((incoming_ascii == " " || incoming_ascii == ",") && isInst) ? FETCHING : ERROR;
                end FETCHING: state <= RETURN;
                RETURN : state <= IDLE;
            endcase

        end else state <= IDLE;
    end

endmodule // instruction_interpreter

module get_address #(
    parameter NUM_INSTRUCTIONS 
    )(
    input wire [4:0][4:0] compressed_inst,
    output wire [$clog2(NUM_INSTRUCTIONS) - 1:0] address,
    output wire isInst
);

    assign isInst = (address != 6'hff);

    always_comb begin
        case (compressed_inst)
            {COMPRESSED__, COMPRESSED__, COMPRESSED_A, COMPRESSED_D, COMPRESSED_D} : address = 6'h00; // add
            {COMPRESSED__, COMPRESSED_A, COMPRESSED_D, COMPRESSED_D, COMPRESSED_I} : address = 6'h01; // addi
            {COMPRESSED__, COMPRESSED__, COMPRESSED_A, COMPRESSED_N, COMPRESSED_D} : address = 6'h02; // and
            {COMPRESSED__, COMPRESSED_A, COMPRESSED_N, COMPRESSED_D, COMPRESSED_I} : address = 6'h03; // andi
            {COMPRESSED_A, COMPRESSED_U, COMPRESSED_I, COMPRESSED_P, COMPRESSED_C} : address = 6'h04; // auipc
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_E, COMPRESSED_Q} : address = 6'h05; // beq
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_G, COMPRESSED_E} : address = 6'h06; // bge
            {COMPRESSED__, COMPRESSED_B, COMPRESSED_G, COMPRESSED_E, COMPRESSED_U} : address = 6'h07; // bgeu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_L, COMPRESSED_T} : address = 6'h08; // blt
            {COMPRESSED__, COMPRESSED_B, COMPRESSED_L, COMPRESSED_T, COMPRESSED_U} : address = 6'h09; // bltu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_B, COMPRESSED_N, COMPRESSED_E} : address = 6'h0A; // bne
            {COMPRESSED__, COMPRESSED__, COMPRESSED_J, COMPRESSED_A, COMPRESSED_L} : address = 6'h0b; // jal
            {COMPRESSED__, COMPRESSED_J, COMPRESSED_A, COMPRESSED_L, COMPRESSED_R} : address = 6'h0c; // jalr
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_B} : address = 6'h0d; // lb
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_B, COMPRESSED_U} : address = 6'h0e; // lbu
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_H} : address = 6'h0f; // lh
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_H, COMPRESSED_U} : address = 6'h10; // lhu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_U, COMPRESSED_I} : address = 6'h11; // lui
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_L, COMPRESSED_W} : address = 6'h12; // lw
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_O, COMPRESSED_R} : address = 6'h13; // or
            {COMPRESSED__, COMPRESSED__, COMPRESSED_O, COMPRESSED_R, COMPRESSED_I} : address = 6'h14; // ori
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_L} : address = 6'h15; // sll
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_L, COMPRESSED_I} : address = 6'h16; // slli
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T} : address = 6'h17; // slt
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_I} : address = 6'h18; // slti
            {COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_I, COMPRESSED_U} : address = 6'h19; // sltiu
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_L, COMPRESSED_T, COMPRESSED_U} : address = 6'h1a; // sltu
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_A} : address = 6'h1b; // sra
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_A, COMPRESSED_I} : address = 6'h1c; // srai
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_L} : address = 6'h1d; // srl
            {COMPRESSED__, COMPRESSED_S, COMPRESSED_R, COMPRESSED_L, COMPRESSED_I} : address = 6'h1e; // srli
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_B} : address = 6'h1f; // sb
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_H} : address = 6'h20; // sh
            {COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_U, COMPRESSED_B} : address = 6'h21; // sub
            {COMPRESSED__, COMPRESSED__, COMPRESSED__, COMPRESSED_S, COMPRESSED_W} : address = 6'h22; // sw
            {COMPRESSED__, COMPRESSED__, COMPRESSED_X, COMPRESSED_O, COMPRESSED_R} : address = 6'h23; // xor
            {COMPRESSED__, COMPRESSED_X, COMPRESSED_O, COMPRESSED_R, COMPRESSED_I} : address = 6'h24; // xori
            default                                                                : address = 6'hff; // no inst
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