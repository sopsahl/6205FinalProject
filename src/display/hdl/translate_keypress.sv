module translate_keypress (
    output logic [7:0]  keypress,   // Decoded data output
    output logic [15:0] char
);

 always_comb begin
    // converts data to sprite characters
    // a = 1, b = 2, c = 3, etc... (uses ascii!!!)
    case(keypress)
        'h15: char = 17;
        'h1d: char = 23;
        'h24: char = 5;
        'h2d: char = 18;
        'h2c: char = 20;
        'h35: char = 25;
        'h3c: char = 21;
        'h43: char = 9;
        'h44: char = 15;
        'h4d: char = 16;
        'h1c: char = 1;
        'h1b: char = 19;
        'h23: char = 4;
        'h2b: char = 6;
        'h34: char = 7;
        'h33: char = 8;
        'h3b: char = 10;
        'h42: char = 11;
        'h4b: char = 12;
        'h1a: char = 26;
        'h22: char = 24;
        'h21: char = 3;
        'h2a: char = 22;
        'h32: char = 2;
        'h31: char = 14;
        'h3a: char = 13;
        'h16: char = 35;
        'h1e: char = 36;
        'h26: char = 37;
        'h25: char = 38;
        'h2e: char = 39;
        'h36: char = 40;
        'h3d: char = 41;
        'h3e: char = 42;
        'h46: char = 43;
        'h45: char = 44;
        'h41: char = 32; // comma
        'h49: char = 33; // period
        'h29: char = 0; // space
        'h5a: char = 48; // enter
        'h66: char = 27; // bksp
        default: char = 0;
    endcase
 end

endmodule