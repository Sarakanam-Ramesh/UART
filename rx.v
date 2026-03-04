`include "rx_dp.v"
`include "baud_gen_os.v"
`include "rx_cp.v"
module rx(
	input rx_in,
	input clk,
	input rst,
	output  rx_busy,
	output  data_ready,
	output  parity_error,
	output  stop_bit_error,
	output  [7:0] rx_data);

	wire baud_tick, start_valid, shift, sample_done, load, check_stop;

	rx_dp dp (.clk(clk),.rst(rst),.rx_in(rx_in),.baud_tick(baud_tick),.shift(shift),.load(load),.check_stop(check_stop),.sample_done(sample_done),.start_valid(start_valid),.sipo_out(rx_data),.data_ready(data_ready),.parity_bit_error(parity_error),.stop_bit_error(stop_bit_error));

	rx_fsm cp(.clk(clk),.rst(rst),.baud_tick(baud_tick),.start_valid(start_valid),.data_ready(data_ready),.shift(shift),.sample_done(sample_done),.load(load),.check_stop(check_stop),.rx_busy(rx_busy));

	baud_gen1 #(.clockfreq(100_000_000),.baud(115200)) dut (.clk(clk),.rst(rst),.baud_tick(baud_tick));

endmodule
