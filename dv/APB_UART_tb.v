`timescale 1ns/100ps

// CTRL_REG >> {'b0,rx_rst,rx_en,tx_rst,tx_en}
// STATS_REG >> {'b0,rx_err,rx_done,rx_busy,tx_done,tx_busy}

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

module APB_UART();

// FSM parameters
parameter IDLE = 2'b00;
parameter WRITE = 2'b01;
parameter READ = 2'b10;

// stimuls
reg PCLK;
reg PRESETn;
reg [31:0] PADDR;
reg PSEL;
reg PENABLE;
reg PWRITE;
reg [31:0] PWDATA;
// response
wire [31:0] PRDATA;
wire PREADY;

// DUT
APB DUT 
        (
            // inputs
            .PCLK(PCLK),
            .PRESETn(PRESETn),
            .PADDR(PADDR),
            .PSEL(PSEL),
            .PENABLE(PENABLE),
            .PWRITE(PWRITE),
            .PWDATA(PWDATA),
    
            // outputs
            .PRDATA(PRDATA),
            .PREADY(PREADY)
        );

// clk generation

initial begin

    PCLK = 0;
    forever
        #5 PCLK = ~PCLK;

end

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

initial begin

    // rst and starting from known value 
    PRESETn = 0;
    PADDR = 32'b0;
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PWDATA = 32'b0;
    repeat(4) @(negedge PCLK);
    // turn off the rst
    PRESETn = 1;
    repeat(4) @(negedge PCLK);

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // starting operations 

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // APB slave will send letter "A" to the TX and RX should receive it

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // writing mode (WRITING LETTER A IN THE TX_DATA)

    // disable any operations and load data in PWDATA and load the address
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd2; // TX_REG ADDRESS
    PWDATA = "A"; // send the letter "A" to TX
    repeat(4) @(negedge PCLK);

    PENABLE = 1; // start writing

    wait(PREADY == 1); // here we are sure that the data has been written and came back to idle again
    @(posedge PCLK); // because PREADY IS HIGH FOR ONE CYCLE

    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    $display(" ");
    $display("THE APB MASTER TOLD THE SLAVE TO LOAD LETTER A IN THE TX IN ORDER TO SEND IT"); // display TX have been loaded
    $display(" ");
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // writing mode (WRITING IN CTRL_REG TO ENABLE UART)

    // enable the tx_enable and rx_enable 

    // disable any operations and load ADD and PWDATA
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0; // CTRL_REG ADDRESS
    PWDATA = 32'd5; // ENABLE tx_enable and rx_enable (the TX should send "A" to the receiver)
    repeat(4) @(negedge PCLK);

    // enable writing again
    PENABLE = 1;


    wait(PREADY == 1); // here we are sure that the data has been written and came back to idle again
    @(posedge PCLK); // because PREADY IS HIGH FOR ONE CYCLE

    $display("TURNING ON THE ENABLES");

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // reading mode (READING THE CTRL_REG TO KONW IF THE ENABLES ARE WORKING)

    // disable any operations and load the ADD of STATS_REG and in order to read it to know if it busy or not
    PENABLE = 0;
    PSEL = 1;
    PADDR = 32'd0;
    PWRITE = 1'b0;
    repeat(4) @(negedge PCLK);

    PENABLE = 1; // enable reading

    wait(PREADY == 1);
    @(posedge PCLK);

    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    $display(" ");
    $display("tx_enable is %b and rx_enable is %b", PRDATA[0], PRDATA[2]);
    $display(" ");
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // writing mode (WRITING IN CTRL_REG TO close the tx_enable and rx_enable)

    // disable any operations and load ADD and PWDATA
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 1;
    PADDR = 32'd0; // CTRL_REG ADDRESS
    PWDATA = 32'd0; // disable tx_enable and rx_enable
    repeat(4) @(negedge PCLK);

    // enable writing again
    PENABLE = 1;


    wait(PREADY == 1); // here we are sure that the data has been written and came back to idle again
    @(posedge PCLK); // because PREADY IS HIGH FOR ONE CYCLE

    $display("TURNING OFF THE ENABLES");

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // reading mode (READING THE CTRL_REG TO MAKE SURE THAT ENABLES ARE OFF)

    // disable any operations and load the ADD of STATS_REG and in order to read it to know if it busy or not
    PENABLE = 0;
    PSEL = 1;
    PADDR = 32'd0;
    PWRITE = 1'b0;
    repeat(4) @(negedge PCLK);

    PENABLE = 1; // enable reading

    wait(PREADY == 1);
    @(posedge PCLK);

    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    $display(" ");
    $display("tx_enable is %b and rx_enable is %b", PRDATA[0], PRDATA[2]);
    $display(" ");
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

    $display("UART SHOULD BE WORKING");
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // reading mode (READING THE STATS_REG TO KONW IF THE BUSY IS WORKING)

    // disable any operations and load the ADD of STATS_REG and in order to read it to know if it busy or not
    PENABLE = 0;
    PSEL = 1;
    PADDR = 32'd1;
    PWRITE = 1'b0;
    repeat(4) @(negedge PCLK);

    PENABLE = 1; // enable reading

    wait(PREADY == 1);
    @(posedge PCLK);
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    $display(" ");
    $display("THE STATE OF tx_busy is %b and rx_busy is %b", PRDATA[0], PRDATA[2]);
    $display(" ");
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // wait for 10 bit time to send and receive the frame

    repeat(10*10417) @(negedge PCLK); // to make sure that the data has been sent and received
    $display("10 BIT CYCLES HAVE FINISHED");
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // reading mode (READING THE STATS_REG TO KONW IF THE DONE IS WORKING)

    // disable any operationsand read STAT_REG
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 0;
    PADDR = 32'd1; // STATS_REG ADDRESS
    repeat(4) @(negedge PCLK);

    PENABLE = 1; // enable reading 

    wait(PREADY == 1); // here we are sure that PRDATA contain the UART_states and came back to idle again
    @(posedge PCLK); // because PREADY IS HIGH FOR ONE CYCLE

    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    $display(" ");
    $display("THE STATE OF tx_done is %b and rx_done is %b", PRDATA[1], PRDATA[3]);
    $display(" ");
    $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

    $display("CHECKING THE RECEIVED INFO");
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // reading mode (READING THE RX TO MAKE SURE THAT THE RX IS WORKING)

    // disable any operations
    PENABLE = 0;
    PSEL = 1;
    PWRITE = 0;
    PADDR = 32'd3; // RX_REG ADDRESS 
    repeat(4) @(negedge PCLK);

    // read RX
    PENABLE = 1;

    wait(PREADY == 1); // here we are sure that PRDATA contain the UART_RX and came back to idle again
    @(posedge PCLK);

    if(PRDATA != "A") begin 
        $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        $display(" ");
        $display("There is an error");
        $display(" ");
        $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    end
    else begin
        $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        $display(" ");
        $display("THE LETTER THAT HAS BEEN RECEIVED IS %s", PRDATA[7:0]);
        $display(" ");
        $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    end

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    $stop;

end

endmodule
