module txmux(
	input start_bit,
	input data_bit,
	input parity_bit,
	input stop_bit,
	input [1:0] sel,
	output reg data_out);

	always @(*) begin
	case(sel)
		2'b00: data_out=start_bit;
		2'b01: data_out=data_bit;
		2'b10: data_out=parity_bit;
		2'b11: data_out=stop_bit;
		default: data_out=1'b1;
	endcase
	end
endmodule
