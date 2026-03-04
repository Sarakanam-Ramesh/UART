module parity_checker(
	input clk, 	//16x baud clock
	input rst,
	input load,
	input rx_in,
	input [7:0] sipo_out,
	output reg parity_bit_error);

	reg pgen;

	always @(posedge clk, posedge rst) begin
		if(rst) begin
			parity_bit_error	<=1'b0;
		end
		else if(load) begin
			pgen	=^sipo_out;
			parity_bit_error	<=(pgen ^ rx_in);
		end
		else begin
			parity_bit_error	<=parity_bit_error;
		end
	end
endmodule			
