`include "txfsm.v"
`include "txmux.v"
`include "piso.v"
`include "paritygen.v"
`include "baud_gen.v"
module tx #(parameter clkfreq=100_000_000, parameter baud=115200)(
	input clk,
	input rst,
	input txstart,
	input [7:0] txdata,
	output txbusy,
	output txdata_out);
	

	wire load, shift, databit, paritybit,baud_tick;
        wire startbit=1'b0;
	wire stopbit=1'b1;
	wire [1:0] sel;

	txfsm b1(.clk(clk),.rst(rst),.txstart(txstart),.baud_tick(baud_tick),.shift(shift),.load(load),.sel(sel),.txbusy(txbusy));

	txmux b2(.start_bit(startbit),.data_bit(databit),.parity_bit(paritybit),.stop_bit(stopbit),.sel(sel),.data_out(txdata_out));

	piso b3(.clk(clk),.rst(rst),.baud_tick(baud_tick),.shift(shift),.load(load),.tx_data(txdata),.databit(databit));
	
	paritygen b4(.clk(clk),.rst(rst),.txdata(txdata),.load(load),.parity_bit(paritybit));

	baud_gen #(clkfreq,baud) dut(.clk(clk),.rst(rst),.baud_tick(baud_tick));
	

endmodule
