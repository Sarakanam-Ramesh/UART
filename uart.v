`include "rx.v"
`include "tx.v"
module uart(
	input [7:0] tx_data,
	input tx_clk,
	input rx_clk,
	input tx_start,
	input rst,
	output tx_busy,
	output [7:0] rx_data,
	output rx_busy,
	output data_ready,
	output parity_error,
	output stop_bit_error);

	wire w1;

	tx tx(.clk(tx_clk),.rst(rst),.txstart(tx_start),.txdata(tx_data),.txbusy(tx_busy),.txdata_out(w1));
	
	rx rx(.clk(rx_clk),.rst(rst),.rx_in(w1),.rx_busy(rx_busy),.data_ready(data_ready),.parity_error(parity_error),.stop_bit_error(stop_bit_error),.rx_data(rx_data));

endmodule
