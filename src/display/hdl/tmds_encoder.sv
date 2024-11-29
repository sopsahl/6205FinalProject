`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
  logic [5:0] num_ones;
  logic [5:0] num_zeros;
  logic [4:0] tally;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
	
	assign num_ones = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7];
	assign num_zeros = !q_m[0]+!q_m[1]+!q_m[2]+!q_m[3]+!q_m[4]+!q_m[5]+!q_m[6]+!q_m[7];
	
	always_ff @(posedge clk_in) begin
		if (rst_in) begin
			tmds_out <= 0;
			tally <= 0;
		end else begin
			if (ve_in) begin // this is where the state logic is contained
				if (tally == 0 || (num_ones == num_zeros)) begin // step 2
					tmds_out <= {!q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]}; // slice the bits for the output
				
					if (q_m[8] == 0) begin
						tally <= tally + (num_zeros - num_ones);
					end else begin
						tally <= tally + (num_ones - num_zeros);
					end
				end else begin
					if (((tally[4] == 0 && tally != 0) && (num_ones > num_zeros)) || ((tally[4] == 1 && tally != 0) && (num_zeros > num_ones))) begin // step 3
						tmds_out <= {1'b1, q_m[8], ~q_m[7:0]}; // step 4
						tally <= tally + (q_m[8]<<1) + (num_zeros - num_ones); // tally + 2*q_m[8] + (# zeros - # ones)
					end else begin
						tmds_out <= {1'b0, q_m[8], q_m[7:0]};
						tally <= tally - ((!q_m[8])<<1) + (num_ones - num_zeros); // tally + 2*~q_m[8] + (# ones - # zeros)
					end
				end
			end else begin
				tally <= 0;
				
				if (control_in == 2'b00) begin
					tmds_out <= 10'b1101010100;
				end else if (control_in == 2'b01) begin
					tmds_out <= 10'b0010101011;
				end else if (control_in == 2'b10) begin
					tmds_out <= 10'b0101010100;
				end else if (control_in == 2'b11) begin
					tmds_out <= 10'b1010101011;
				end
			end
		end
	end
endmodule
 
`default_nettype wire