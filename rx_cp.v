module rx_fsm (

    input clk,
    input rst,
    input baud_tick,
    input start_valid,
    input data_ready,   

    output reg shift,
    output reg sample_done,
    output reg load,
    output reg check_stop,
    output reg rx_busy
);

    
    parameter IDLE   = 3'b000;
    parameter START  = 3'b001;
    parameter DATA   = 3'b010;
    parameter PARITY = 3'b011;
    parameter STOP   = 3'b100;

    reg [2:0] state, next_state;

    reg [3:0] sample_count;   
    reg [2:0] bit_count;     

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            sample_count <= 0;
    	else if(start_valid) sample_count<=0;
        else if (baud_tick) begin
            if (sample_count == 15)
                sample_count <= 0;
            else
                sample_count <= sample_count + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            bit_count <= 0;
        else if (state == DATA && sample_done) begin
            if (bit_count == 7)
                bit_count <= 0;
            else
                bit_count <= bit_count + 1;
        end
    end

    always @(*) begin
        if (sample_count == 7 && baud_tick)
            sample_done = 1;
        else
            sample_done = 0;
    end

    always @(*) begin
        case (state)

            IDLE: begin
                if (start_valid)
                    next_state = START;
                else
                    next_state = IDLE;
            end

            START: begin
                /*if (sample_done)
                    next_state = DATA;
                else
                    next_state = START;*/
                    next_state = DATA;
            end

            DATA: begin
                if (sample_done && bit_count == 7)
                    next_state = PARITY;
                else
                    next_state = DATA;
            end

            PARITY: begin
                if (sample_done)
                    next_state = STOP;
                else
                    next_state = PARITY;
            end

            STOP: begin
                if (sample_done)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end

            default: next_state = IDLE;

        endcase
    end

    always @(*) begin
        shift        = 0;
        load  = 0;
        check_stop   = 0;
        rx_busy      = 1;

        case (state)

            IDLE: begin
                rx_busy = 0;
            end

            START: begin
            end

            DATA: begin
                if (sample_done)
                    shift = 1;
            end

            PARITY: begin
                if (sample_done)
                    load = 1;
            end

            STOP: begin
                if (sample_done)
                    check_stop = 1;
            end

        endcase
    end

endmodule
