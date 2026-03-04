`include "uart.v"
module uart_tb;
	reg [7:0] tx_data;
	reg clk;
	reg tx_start;
	reg rst;
	wire tx_busy;
	wire [7:0] rx_data;
	wire rx_busy;
	wire data_ready;
	wire parity_error;
	wire stop_bit_error;
	
	uart dut(.tx_clk(clk),.rx_clk(clk),.tx_start(tx_start),.tx_data(tx_data),.rst(rst),.tx_busy(tx_busy),.rx_data(rx_data),.rx_busy(rx_busy),.data_ready(data_ready),.parity_error(parity_error),.stop_bit_error(stop_bit_error));
	
	always #5 clk=~clk;

	initial begin
		clk	=1'b0;
		tx_start=1'b0;
		rst	=1'b0;
		tx_data	=8'h88;
		$monitor("rst=%b,tx_start=%b,tx_busy=%b,tx_data=%b,rx_data=%b,rx_busy=%b,data_ready=%b,parity_error=%b,stop_bit_error=%b",rst,tx_start,tx_busy,tx_data,rx_data,rx_busy,data_ready,parity_error,stop_bit_error);

		@(posedge clk) rst=1'b1;
		@(posedge clk);
		@(posedge clk) rst=1'b0;
		repeat(5) @(posedge clk);
		tx_start =1'b1;
		@(posedge clk) tx_start=1'b0;
		repeat(12_000) @(posedge clk);
		//wait(rx_busy==0)
		$finish;
	end
endmodule
		
