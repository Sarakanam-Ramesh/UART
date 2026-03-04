module paritygen(
	input clk,
	input rst,
	input [7:0] txdata,
	input load,
	output reg parity_bit);

	always @(posedge clk,posedge rst) begin
		if(rst) begin
			parity_bit<=1'b0;
		end
		else if(load) begin
			parity_bit<= ^txdata;	// data loaded
		end
		else parity_bit<=parity_bit;	//has to retains it previous value until next load
	end
endmodule
	
