`timescale 1ns / 1ps
`default_nettype none

// immediate_interpreter: takes the immediate value (0 - FF_FF_FF_FF)
// Up to 4 bytes of data (8 characters)
// Calculates the immediate output 
module immediate_interpreter (
    input wire clk_in,
    input wire rst_in,
    input wire trigger_in,
    input wire [7 : 0] incoming_ascii,
    output logic error_flag,
    output logic done_flag,
    output logic busy_flag,

    output logic [31:0] immediate
);

    typedef enum {
        IDLE, 
        BUSY,
        RETURN,
        ERROR
    } state_t state;

    assign error_flag = (state == ERROR);
    assign done_flag = (state == RETURN);
    assign busy_flag = (state != IDLE);

    logic is_hex;
    logic [3:0] value;

    _ascii_to_hex conversion (
        .ascii_char(incoming_ascii),
        .hex_val(value),
        .is_hex(is_hex)
    );

    always_ff @(posedge clk_in) begin
        
        if (rst_in) begin
            state <= IDLE;
            immediate <= 0;

        end else begin
            case (state) 
                IDLE: begin
                    if (trigger_in) begin
                        state <= (is_hex) ? BUSY : ERROR;
                        immediate <= value;
                    end 
                end BUSY: begin
                    if (is_hex) immediate <= ((immediate << 4) || value);
                    else state <= (incoming_ascii == "'") ? RETURN : ERROR;
                end RETURN: state <= IDLE;
            endcase
        end
    end

endmodule // immediate_interpreter


module _ascii_to_hex (
    input wire [7:0] ascii_char,
    output logic [3:0] hex_val,
    output logic is_hex
);

    logic is_num, is_let;
    assign is_num = (ascii_char >= "0" && ascii_char <= "9");
    assign is_let = (ascii_char >= "a" && ascii_char <= "f") || (ascii_char >= "A" && ascii_char <= "F");
    
    assign is_hex = is_num || is_let;
    assign hex_val = (is_num) ? ascii_char[3:0] : (is_let) ? ascii_char[3:0] + 4'h9 : 4'h0;

endmodule // _ascii_to_hex

`default_nettype wire