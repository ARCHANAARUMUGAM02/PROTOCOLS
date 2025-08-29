`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.08.2025 18:55:03
// Design Name: 
// Module Name: abp_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_apb_top_module;
    reg         pclk;
    reg         presetn;
    reg         transfer;
    reg         pwrite_in;
    reg  [7:0]  pwdata_in;
    reg  [7:0]  paddr_in;
    wire [7:0]  read_data_out;

    apb_top_module DUT (
        .pclk(pclk),
        .presetn(presetn),
        .transfer(transfer),
        .pwrite_in(pwrite_in),
        .pwdata_in(pwdata_in),
        .paddr_in(paddr_in),
        .read_data_out(read_data_out)
    );

    always #5 pclk = ~pclk;

    initial begin
        pclk = 0;
        presetn = 0;
        transfer = 0;
        pwrite_in = 0;
        pwdata_in = 8'h00;
        paddr_in = 8'h00;

    
        #10;
        presetn = 1;  
        #10;
        transfer = 1;
        pwrite_in = 1;       
        paddr_in = 8'h05;    
        pwdata_in = 8'hAA;   
        #20;
        transfer = 0;

        #20;

        
        transfer = 1;
        pwrite_in = 0;       
        paddr_in = 8'h05;    
        #20;
        transfer = 0;

        #50;
        $display("Read Data = %h", read_data_out);

        $stop;
    end

endmodule




