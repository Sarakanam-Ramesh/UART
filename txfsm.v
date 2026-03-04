/*module txfsm(
	input clk,
	input rst,
	input txstart,
	input baud_tick,
	output reg shift,
	output reg load,
	output reg [1:0] sel,
	output reg txbusy);

	reg [3:0] count;
	reg [2:0] ns,ps;
	reg count_en;

	localparam IDLE=3'b000;
	localparam START=3'b001;
	localparam DATA=3'b010;
	localparam PARITY=3'b011;
	localparam STOP=3'b100;

	always @(posedge clk, posedge rst) begin
		if(rst) begin
			ps<=IDLE;	//no need of resetting next state
		end
		else //if(baud_tick) begin
			ps<=ns;
		//end
		//else ps<=ps;
	end

	always @(posedge clk, posedge rst) begin
		if (rst) count<=0;
		else if(baud_tick) begin
		       if(count_en) count<=count+1;
		       else count<=0;
	        end
		else count<=count;
	end

	always @(*) begin
		// default to avoid latches if any 
	        ns       = ps;
        	shift    = 0;
        	load     = 0;
        	sel      = 2'b11;
        	txbusy   = 0;
        	count_en = 0;

		case(ps)
		IDLE: begin
			if(txstart) ns=START;
			else ns	=IDLE;
			shift	=0;
			load	=0;
			sel	=2'b11;
			txbusy	=0;
			count_en=0;
		end
		START: begin
			ns	=DATA;
			load	=1;	//for data loading
			shift	=0;
			sel	=2'b00;
			txbusy	=1;
			count_en=0;
		end
		DATA: begin
			if(count==7) ns=PARITY;
			else ns=DATA;
			load	=0;	//for parity loading
			shift	=(baud_tick && count<7);
			sel	=2'b01;
			txbusy	=1;
			count_en=1;
		end
		PARITY: begin
			ns	=STOP;
			load	=0;
			shift	=0;
			sel	=2'b10;
			txbusy	=1;
			count_en=0;
		end
		STOP: begin
			ns	=IDLE;
			load	=0;
			shift	=0;
			sel	=2'b11;
			txbusy	=0;
			count_en=0;
		end
		default: begin
			ns	=IDLE;
			shift	=0;
			load	=0;
			sel	=2'b00;
			txbusy	=0;
			count_en=0;
		end
		endcase
	end
endmodule*/

module txfsm(
	input clk,
	input rst,
	input txstart,
	input baud_tick,
	output reg shift,
	output reg load,
	output reg [1:0] sel,
	output reg txbusy);

	reg [3:0] count;
	reg [2:0] ns,ps;


	localparam IDLE=3'b000;
	localparam START=3'b001;
	localparam DATA=3'b010;
	localparam PARITY=3'b011;
	localparam STOP=3'b100;

	//present state logic
	always @(posedge clk, posedge rst) begin
		if(rst) begin 
			ps<=IDLE;
		end
		else ps<=ns;
	end

	// count logic
	always @(posedge clk, posedge rst) begin
		if(rst) count<=1'b0;
		else if(baud_tick && ps==DATA) count<=count+1;
		else if(ps!=DATA)count<=1'b0;
	end

	//next state logic
	always @(*) begin
	        //ns       = ps;
		case(ps)
			IDLE: begin
				if(txstart) ns=START;
				else ns=IDLE;
			end
			START: begin
				if(baud_tick)ns=DATA;
				else ns=START;
			end
			DATA: begin
				if(baud_tick) begin
					if(count==7) ns=PARITY;
					else ns=DATA;
				end
				else ns=DATA;
			end
			PARITY: begin
				if(baud_tick) ns=STOP;
				else ns=PARITY;
			end
			STOP: begin
				if(baud_tick) ns=IDLE;
				else ns=STOP;
			end
			default: ns=IDLE;
		endcase
	end

	//output logic
	always @(*) begin

        	shift    = 1'b0;
        	load     = 1'b0;
        	sel      = 2'b11;
        	txbusy   = 1'b0;

		case(ps)
			IDLE: begin
				shift	=1'b0;
				load	=1'b0;
				sel	=2'b11;
				txbusy	=1'b0;
			end
			START: begin
				shift	=1'b0;
				load	=1'b1;
				sel	=2'b00;
				txbusy	=1'b1;
			end
			DATA: begin
				shift	=(baud_tick && count<8);
				load	=1'b0;
				sel	=2'b01;
				txbusy	=1'b1;
			end
			PARITY: begin
				shift	=1'b0;
				load	=1'b0;
				sel	=2'b10;
				txbusy	=1'b1;
			end
			STOP: begin
				shift	=1'b0;
				load	=1'b0;
				sel	=2'b11;
				txbusy	=1'b0;	//if tx busy 1 then this comment reflects. must be busy untill it reached idle
			end
			default: begin
				shift	=1'b0;
				load	=1'b0;
				sel	=2'b11;
				txbusy	=1'b0;
			end
		endcase
	end
endmodule

/*# sending: data_in=aabbccdd11223344556677889900eeff
# T=0 | wr=0 rd=0 | tx_busy=x txf_full=x txf_empty=x | rx_busy=x rxf_full=x rxf_empty=x | data_out=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx | par_err=x stop_err=
x
# T=5 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err=
0
# T=35 reset applied successfully
# T=45 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=55 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=65 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=75 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=85 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=95 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_err
=0
# T=105 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=115 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=125 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=135 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=145 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=155 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=165 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=175 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=185 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=195 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=205 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=215 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=225 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=235 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=245 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=255 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=265 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=275 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=285 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=295 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=305 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=315 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=325 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=335 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=345 | wr=1 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=355 tx fifo loaded successfully txfifo_full=0 txfifo_empty=0
# T=355 | wr=0 rd=0 | tx_busy=0 txf_full=1 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=365 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_er
r=0
# T=4905 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=1 | data_out=00000000000000000000000000000000 | par_err=0 stop_e
rr=0
# T=70245 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop_
err=0
# T=87515 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop_
err=0
# T=95515 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop_
err=0
# T=95525 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop_
err=0
# T=99945 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop_
err=0
# T=183095 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=190995 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=191005 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=195525 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=278675 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=286475 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=286485 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=291105 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=373715 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=381955 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=381965 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=386685 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=469295 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=477435 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=477445 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=482265 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=564875 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=572915 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=572925 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=577305 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=660455 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=668395 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=668405 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=672885 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=756035 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=763875 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=763885 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=768465 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=851615 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=859355 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=859365 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=864045 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=946655 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=954835 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=954845 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=959625 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 stop
_err=0
# T=1042235 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1050315 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1050325 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1055205 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1137815 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1145795 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1145805 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1150245 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1233395 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1241275 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1241285 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1245825 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1328975 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1336755 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1336765 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1341405 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1424555 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1432235 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=0 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1432245 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1436985 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=1 | rx_busy=1 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1502325 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=1 | rx_busy=1 rxf_full=1 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1519595 | wr=0 rd=0 | tx_busy=1 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=1 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=1527715 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=1 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000365 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=1 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000375 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000385 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000395 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000ff | par_err=0 sto
p_err=0
# T=2000405 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000ff | par_err=0 sto
p_err=0
# T=2000415 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000ee | par_err=0 sto
p_err=0
# T=2000425 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000ee | par_err=0 sto
p_err=0
# T=2000435 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000445 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000000 | par_err=0 sto
p_err=0
# T=2000455 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000099 | par_err=0 sto
p_err=0
# T=2000465 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000099 | par_err=0 sto
p_err=0
# T=2000475 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000088 | par_err=0 sto
p_err=0
# T=2000485 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000088 | par_err=0 sto
p_err=0
# T=2000495 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000077 | par_err=0 sto
p_err=0
# T=2000505 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000077 | par_err=0 sto
p_err=0
# T=2000515 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000066 | par_err=0 sto
p_err=0
# T=2000525 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000066 | par_err=0 sto
p_err=0
# T=2000535 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000055 | par_err=0 sto
p_err=0
# T=2000545 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000055 | par_err=0 sto
p_err=0
# T=2000555 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000044 | par_err=0 sto
p_err=0
# T=2000565 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000044 | par_err=0 sto
p_err=0
# T=2000575 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000033 | par_err=0 sto
p_err=0
# T=2000585 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000033 | par_err=0 sto
p_err=0
# T=2000595 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000022 | par_err=0 sto
p_err=0
# T=2000605 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000022 | par_err=0 sto
p_err=0
# T=2000615 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000011 | par_err=0 sto
p_err=0
# T=2000625 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=00000000000000000000000000000011 | par_err=0 sto
p_err=0
# T=2000635 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000dd | par_err=0 sto
p_err=0
# T=2000645 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000dd | par_err=0 sto
p_err=0
# T=2000655 | wr=0 rd=0 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000cc | par_err=0 sto
p_err=0
# T=2000665 | wr=0 rd=1 | tx_busy=0 txf_full=0 txf_empty=1 | rx_busy=0 rxf_full=0 rxf_empty=0 | data_out=000000000000000000000000000000cc | par_err=0 sto
p_err=0
# T=2000675 | reading from rx fifo is successfull data_out =000000000000000000000000000000cc rxfifo_full=0 rxfifo_empty=0
# data_in (sent) =aabbccdd11223344556677889900eeff | data_out (received) =000000000000000000000000000000cc | parity_error =0 | stop_error =0*/			
