module piso(
	input clk,
	input rst,
	input baud_tick,
	input shift,
	input load,
	input [7:0] tx_data,
	output databit);

	reg [7:0] temp;

	always @(posedge clk,posedge rst) begin
		if(rst) temp<=8'b00_00_00_00;
		else if (baud_tick) begin
			if(load) temp<=tx_data;
			else if(shift) temp<={1'b0,temp[7:1]};
			else temp<=temp;
		end
		else temp<=temp;
	end
	assign databit=temp[0];
endmodule
