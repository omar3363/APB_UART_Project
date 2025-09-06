module receiver
(
    // inputs
    input clk,
    input rst,
    input arst_n,
    input rx_en,
    input RX,

    // outputs
    output reg busy,
    output reg done,
    output reg err,
    output [7:0] data // to get the data SIPO
);
// FSM parameters 
parameter IDLE = 3'b000;
parameter START = 3'b001;
parameter DATA = 3'b010;
parameter ERR = 3'b011;
parameter DONE = 3'b100;
// FSM internal signals (cs and ns)
reg [2:0] cs,ns;

// internal signals (baud_counter)
reg [13:0] baud_counter; // counter
reg load_baud_start; // to load 1.5 bit time
reg load_baud_data; // to load 1 bit time
wire zero_flag; // the zero flag that is the response of the counter

// internal signals (bit_counter)
reg [3:0] bit_counter;  // counter (start + 8 data + stop = 10)

// internal signals (SIPO)
reg en_SIPO; // enable the serial in parallel out shift register
reg [9:0] SIPO_reg; // contain (start_bit - data - stop_bit)

// internal signals (edge detector)
wire edge_detect;
reg RX_reg;
reg RX_temp;

// edge detector design
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n) begin 
        RX_reg <= 1'b1;
        RX_temp <= 1'b1;
    end

    // sync rst
    else if(rst) begin 
        RX_reg <= 1'b1;
        RX_temp <= 1'b1;
    end
    // design
    else begin
        RX_temp <= RX_reg;
        RX_reg <= RX;
    end
end

assign edge_detect = (RX_temp == 1 && RX_reg == 0)? 1 : 0;


// baud_counter design
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n)
        baud_counter <= 14'b0;

    // sync rst
    else if(rst)
        baud_counter <= 14'b0;

    // 1.5 bit time cycles
    else if(load_baud_start)
        baud_counter <= 14'd5207; // (5208-1) down to zero to get 5208 cycles whick means 0.5 bit time

    // 1 bit time cycles
    else if(load_baud_data)
        baud_counter <= 14'd10416; // (10417-1) down to zero to get 10417 cycles whick means 1 bit time

    // decrement
    else if(baud_counter != 14'b0)
        baud_counter <= baud_counter - 1'b1; // decrement by 1

end
assign zero_flag = (baud_counter == 0)? 1 : 0;

// bit_counter design
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n)
        bit_counter <= 4'b0;

    // sync rst
    else if(rst)
        bit_counter <= 4'b0;

    // idle case
    else if(cs == IDLE)
        bit_counter <= 4'b0;

    //increment
    else if(cs == DATA && zero_flag) 
        bit_counter <= bit_counter + 1'b1;

end

// SIPO design
always @(posedge clk or negedge arst_n) begin

    // async rst
    if(~arst_n)
        SIPO_reg <= 10'b0;

    // sync rst
    else if(rst)
        SIPO_reg <= 10'b0;    
    
    // converting
    else if(en_SIPO && zero_flag) 
        SIPO_reg <= {RX,SIPO_reg[9:1]};
end
assign data = SIPO_reg [7:0];


// handling done and err flags
always @(posedge clk or negedge arst_n) begin
    // Asynchronous reset
    if (~arst_n) begin
        done <= 1'b0;
        err <= 1'b0;
    end
    // Synchronous reset (clears the flags)
    else if (rst) begin
        done <= 1'b0;
        err <= 1'b0;
    end
    // Set flags based on FSM state
    else begin
        if (cs == DONE)
            done <= 1'b1;
        if (cs == ERR)
            err <= 1'b1;
    end
end


// FSM

// state memory
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

//ns
always @(*) begin

        busy = 1'b0;
        load_baud_start = 1'b0;
        load_baud_data  = 1'b0;
        en_SIPO         = 1'b0;
        
    case(cs)

    IDLE : begin
    
        busy = 1'b0;
        load_baud_start = 1'b0;
        load_baud_data  = 1'b0;
        en_SIPO         = 1'b0;
    
        if(edge_detect && rx_en) begin
            ns = START;
            load_baud_start = 1;
            busy = 1'b1;
        end
        
        end

    START : begin

        busy = 1'b1;

        if(zero_flag) begin
            ns = DATA;
            load_baud_start = 1'b1;
        end

        end

    DATA : begin

        busy = 1'b1;
        en_SIPO = 1'b1;

        if(zero_flag) begin
            load_baud_data = 1'b1;
            if(bit_counter == 4'd9) begin
                if(RX == 1'b1)
                    ns = DONE;
                else
                    ns = ERR;
            end
        end
        end

    ERR : ns = IDLE;

    DONE : ns = IDLE;


    default : ns = IDLE;

    endcase
end

endmodule 
