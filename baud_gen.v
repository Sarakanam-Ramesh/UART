module baud_gen#(parameter clockfreq=100_000_000, parameter baud=115200)(
	input clk,
	input rst,
	output reg baud_tick);

	localparam divisor =clockfreq/baud;

	localparam width=$clog2(divisor);

	reg [width-1:0] count;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			count<=0;
			baud_tick<=0;
		end
		else if(count==divisor-1) begin
			count<=0;
			baud_tick<=1;
		end
		else begin
			count<=count+1;
			baud_tick<=0;
		end
	end
endmodule

