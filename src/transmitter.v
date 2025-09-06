module transmitter
(
    // inputs
    input tx_en,
    input [7:0] data,
    input arst_n,
    input rst,
    input clk,

    // outputs
    output reg TX,
    output reg busy,
    output reg done
);

// FSM parameters
parameter IDLE = 2'b00;
parameter DATA = 2'b01;
parameter ERR = 2'b10;
parameter DONE = 2'b11;

// FSM internal signals
reg [1:0] cs,ns;

// internal signals (baud_counter)
reg [13:0] baud_counter;
reg load_baud_transmitter;
wire zero_flag;

// internal signals (counter)
reg [3:0] counter;

// internal signals (PISO)
reg [9:0] frame_shift;
reg en_PISO;

// baud_counter design
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n)
        baud_counter <= 14'b0;

    // sync rst
    else if(rst)
        baud_counter <= 14'b0;

    // design
    else if(load_baud_transmitter)
        baud_counter <= 14'd10416; //10416 down to 0 which is 1 bit time

    else if(baud_counter != 14'b0)
        baud_counter <= baud_counter - 1'b1;

end

assign zero_flag = (baud_counter == 14'b0)? 1:0;

//PISO and Counter
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n) begin

        frame_shift <= 10'b0;
        counter <= 4'b0;

    end

    // sync rst
    else if(rst) begin 

        frame_shift <= 10'b0;
        counter <= 4'b0;

    end

    // TX = 1 in cs == IDLE and loading the frame
    else if(cs ==IDLE && tx_en) begin

            frame_shift <= {1'b1,data[7:0],1'b0};
            counter <= 4'b0;  

    end

    // design
    else if(en_PISO && zero_flag) begin

        //parallel to serial sending the (start bit - data by LSB first - stop bit)
        frame_shift <= (frame_shift >> 1);
        //increasing the counter
        counter <= counter + 1'b1;

    end
end


// handling done and err flags
always @(posedge clk or negedge arst_n) begin
    // Asynchronous reset
    if (~arst_n) begin
        done <= 1'b0;
    end
    // Synchronous reset (clears the flags)
    else if (rst) begin
        done <= 1'b0;
    end
    // Set flags based on FSM state
    else begin
        if (cs == DONE)
            done <= 1'b1;
    end
end


// FSM state memory
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n)
        cs <= IDLE;

    // sync rst
    else if(rst)
        cs <= IDLE;

    else
        cs <= ns;

end

// FSM ns
always @(*) begin

    load_baud_transmitter = 1'b0;
    en_PISO = 1'b0;
    busy = 1'b0;
    TX = 1'b1;

    case(cs)

    IDLE : begin

        if(tx_en) begin
            ns = DATA;
            load_baud_transmitter = 1'b1;
            busy = 1'b1;
        end

    end

    DATA : begin

        TX = frame_shift[0];
        en_PISO = 1'b1;
        busy = 1'b1;

        if(zero_flag) begin

            load_baud_transmitter = 1'b1; // to start loading again

            //check counting
            if(counter == 4'd9) begin

                if(TX == 1'b1)
                    ns = DONE;

                else
                    ns = ERR;

            end
        end
    end

    DONE : ns = IDLE;

    ERR : ns = IDLE;

    default : ns = IDLE;

endcase
end

endmodule
