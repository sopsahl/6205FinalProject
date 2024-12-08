`default_nettype none

module  debouncer #(parameter CLK_PERIOD_NS = 10,
                    parameter DEBOUNCE_TIME_MS = 5
                    )
  ( input wire clk_in,
    input wire rst_in,
    input wire dirty_in,
    output logic clean_out);
  //added a int cast
  localparam COUNTER_SIZE = $clog2(500_000);
  logic [COUNTER_SIZE-1:0] counter;
  logic old_dirty_in; //need to remember
  always_ff @(posedge clk_in)begin
    old_dirty_in <= dirty_in;
    if(rst_in)begin
      clean_out <= dirty_in;
      counter <= 0;
    end else begin//normal operation:
      if(dirty_in != old_dirty_in)begin
        counter <= 0;
      end else if(counter==499_999)begin
        clean_out <= dirty_in;
      end else begin
        counter <= counter + 1;
      end
    end
  end

endmodule


`default_nettype wire
