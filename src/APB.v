module APB
(
    // inputs
    input PCLK,
    input PRESETn,
    input [31:0] PADDR,
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [31:0] PWDATA,
    
    // outputs
    output reg [31:0] PRDATA,
    output reg PREADY
);

// UART registers
reg [31:0] CTRL_REG; // {'b0,rx_rst,rx_en,tx_rst,tx_en}
reg [31:0] TX_DATA;

wire [31:0] RX_DATA;
wire [31:0] STATS_REG;

// FSM parameters
parameter IDLE = 2'b00;
parameter WRITE = 2'b01;
parameter READ = 2'b10;

// FSM reg
reg [1:0] cs,ns;


// TX initialization
wire tx;
wire tx_busy,tx_done;

transmitter transmitter_UART
(
    // inputs
    .tx_en(CTRL_REG[0]),
    .data(TX_DATA[7:0]),
    .arst_n(PRESETn),
    .rst(CTRL_REG[1]),
    .clk(PCLK),

    // outputs
    .TX(tx),
    .busy(tx_busy),
    .done(tx_done)
);


// RX initialization
wire rx_busy,rx_done,rx_err;
wire [7:0] rx_data_wire;

receiver receiver_UART
(
    // inputs
    .clk(PCLK),
    .rst(CTRL_REG[3]),
    .arst_n(PRESETn),
    .rx_en(CTRL_REG[2]),
    .RX(tx),

    // outputs
    .busy(rx_busy),
    .done(rx_done),
    .err(rx_err),
    .data(rx_data_wire)
);

assign STATS_REG = {27'b0,rx_err,rx_done,rx_busy,tx_done,tx_busy};
assign RX_DATA = {24'b0, rx_data_wire};

// reg update
always @(posedge PCLK or negedge PRESETn) begin

    if(~PRESETn) begin

        CTRL_REG <= 32'b0;
        TX_DATA <= 32'b0;

    end

    else begin

        if(cs == WRITE) begin

            case(PADDR)
                32'd0 : CTRL_REG <= PWDATA;
                32'd2 : TX_DATA <= PWDATA;
                default : ;
            endcase

        end
    end
end

// state memory
always @(posedge PCLK or negedge PRESETn) begin

    if(~PRESETn)
        cs <= IDLE;
    else
        cs <= ns;

end

// ns
always @(*) begin


    PREADY = 1'b0;
    ns = cs;

    case(cs)

        IDLE : begin

            PREADY = 1'b0;

            if(PENABLE && PSEL && PWRITE)
                ns = WRITE;

            else if(PENABLE && PSEL && ~PWRITE)
                ns = READ;

        end

        WRITE : begin

            PREADY = 1'b1;
            ns = IDLE;

        end

        READ : begin

            PREADY = 1'b1;

            case(PADDR) 

                32'd0 : PRDATA = CTRL_REG;
                32'd1 : PRDATA = STATS_REG;
                32'd2 : PRDATA = TX_DATA;
                32'd3 : PRDATA = RX_DATA;

                default : PRDATA = 32'b0;

            endcase

            ns = IDLE;

        end

        default : ns = IDLE;

    endcase
end

endmodule
