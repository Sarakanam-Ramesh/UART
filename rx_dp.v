`include "detect_start.v"
`include "sipo.v"
`include "parity_checker.v"
`include "stop_checker.v"

module rx_dp(
	input clk,
	input rst,
	input rx_in,
	input baud_tick,
	input shift,sample_done,check_stop,load,	// for making sync between fsm and dp
	output start_valid,
	output [7:0] sipo_out,
	output data_ready,
	output parity_bit_error,
	output stop_bit_error);

	start_detector_16x start (.clk(clk),.rst(rst),.rx_in(rx_in),.baud_tick(baud_tick),.start_valid(start_valid));

	sipo sipo (.clk(clk),.rst(rst),.rx_in(rx_in),.shift(shift),.sample_done(sample_done),.sipo_out(sipo_out),.data_ready(data_ready));

	parity_checker parity(.clk(clk),.rst(rst),.rx_in(rx_in),.load(load),.sipo_out(sipo_out),.parity_bit_error(parity_bit_error));

	stopbit_checker stop(.clk(clk),.rst(rst),.rx_in(rx_in),.check_stop(check_stop),.stopbit_error(stop_bit_error));

endmodule
