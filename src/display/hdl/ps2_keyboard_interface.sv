module ps2_keyboard_interface (
    input  logic        clk,        // FPGA clock
    input  logic        rst,        // Synchronous reset
    input  logic        ps2_clk,    // PS/2 clock from keyboard
    input  logic        ps2_data,   // PS/2 data from keyboard
    output logic [7:0]  data_out,   // Decoded data output
    output logic        key_pressed,  // Data valid signal
    output logic        enter_pressed,
    output logic        bksp_pressed
);
    // Synchronize PS/2 clock and data to FPGA clock domain
    logic ps2_clk_sync0, ps2_clk_sync1;
    logic ps2_data_sync0, ps2_data_sync1;
    logic ps2_clk_falling_edge;
    //NOTE THAT DATA IS IDLE WHEN HIGH 
    always_ff @(posedge clk) begin
        ps2_clk_sync0 <= ps2_clk;
        ps2_data_sync0 <= ps2_data;
        ps2_clk_sync1 <= ps2_clk_sync0;
        ps2_data_sync1 <= ps2_data_sync0;
    end
    //is this a falling edge 
    assign ps2_clk_falling_edge = ps2_clk_sync1 & !ps2_clk_sync0;
    //state machine for data 
    typedef enum logic [2:0] {
        IDLE,
        PROCESSING,
        DONE,
        ERROR
    } state_t;
    state_t state, next_state;
    logic [10:0] full_message;
    logic [7:0] data;
    logic [1:0] key_down;
    //so we have 11 bits and we need to count to 11 
    logic [3:0] data_counter;
    always_ff@(posedge clk)begin 
        if(rst) begin 
            state <=IDLE;
            data_counter <= 0;
            full_message <= 11'b0;
            data <= 8'b0;
            key_pressed <= 0;
            enter_pressed <= 0;
            bksp_pressed <= 0;
            key_down <= 0;
        end
        else begin
            //we just sampled a falling edge 
            if(ps2_clk_falling_edge)begin 
                case(state)
                IDLE: begin 
                    //if it drops we have a data
                    if(ps2_data_sync1 == 1'b0)begin 
                        state <= PROCESSING;
                        data_counter <= 1;
                        full_message <= 11'b0;
                        data <= 8'b0;
                    end
                    else begin 
                        state <= IDLE;
                    end
                end 
 
                PROCESSING:begin 
                    if(data_counter == 9)begin 
                        state <= DONE;
                        // full_message later 
                        //check parity HERE MAYBE
                    end
                    else begin 
                        // full_message<= {full_message[9:0],ps2_data_sync1};
                        data_counter <= data_counter + 1;
                        // state <= PROCESSING
                    end
                    full_message[data_counter] <= ps2_data_sync1;
                end
 
                DONE:begin
                    //stop bit
                    if(ps2_data_sync1 == 1'b1)begin 
                        state <= IDLE;
                        data <= full_message[8:1];

                        if (key_down == 0) begin
                            data_out <= full_message[8:1];

                            if (full_message[8:1] == 'h5a) begin
                                enter_pressed <= 1;
                            end else if (full_message[8:1] == 'h66) begin
                                bksp_pressed <= 1;
                            end else begin
                                key_pressed <= 1;
                            end
                        end

                        key_down <= key_down + 1;

                    end
                    else begin 
                        state <= ERROR;
                    end
                end 
 
                endcase 
 
            end else begin
                key_pressed <= 0;
                enter_pressed <= 0;
                bksp_pressed <= 0;
            end
        end
    end 

endmodule // ps2_keyboard_interface

//scroll up: sw13+enter key.    scroll down: sw12+enter.    compile msg: sw15+enter.      idling msg: sw14+enter