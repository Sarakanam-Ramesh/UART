/*module detect_start(
	input rx_in,
	output start_detected);

	assign start_detected=!(rx_in);
endmodule*/

module start_detector_16x (
    input        clk,        // 16x baud clock
    input        rst,
    input        rx_in,
    input 	 baud_tick,
    output reg   start_valid
);

    reg rx_d;                // delayed rx
    reg   busy;        // indicates start detection in progress
    reg [3:0] sample_cnt;    // 0 to 15 counter
    reg fell;   // latches that a falling edge occurred

    // edge detection
    wire falling_edge = rx_d & ~rx_in;

    // register previous rx
    always @(posedge clk or posedge rst) begin
        if (rst)
            rx_d <= 1'b1;
        else
            rx_d <= rx_in;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            fell <= 0;
        else if (fell && baud_tick)  // clear after baud_tick consumes it
            fell <= 0;
        else if (falling_edge)       // set whenever edge is seen
            fell <= 1;
    end

    // main logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_cnt  <= 4'd0;
            start_valid <= 1'b0;
            busy        <= 1'b0;
        end else if(baud_tick) begin

            start_valid <= 1'b0;  // default

            // if not busy, look for falling edge
            if (!busy) begin
                if (fell) begin
                    busy       <= 1'b1;
                    sample_cnt <= 4'd0;
                end
            end
            else begin
                sample_cnt <= sample_cnt + 1'b1;

                // mid start bit check at sample 7
                if (sample_cnt == 4'd7) begin
			if (rx_in == 1'b0) begin
                        	start_valid <= 1'b1;   // confirmed start
				busy	<=1'b0;
			end
			else
                        	busy <= 1'b0;          // false start, cancel
                end

                // finish after 16 samples
                if (sample_cnt == 4'd15) begin
                    busy <= 1'b0;
                end
            end
        end
    end

endmodule
