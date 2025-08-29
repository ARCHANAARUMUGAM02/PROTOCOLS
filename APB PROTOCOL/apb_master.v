`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.08.2025 14:18:59
// Design Name: 
// Module Name: apb_master
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


module apb_master(
    input  wire pclk,       
    input  wire presetn,    // Active-low reset
    input  wire transfer,      
    input  wire  pwrite_in,  // 1 = write, 0 = read
    input  wire [7:0] pwdata_in,  
    input  wire [7:0] paddr_in, 
    input  wire  pready,     
    input  wire [7:0] prdata,   
    output reg  psel,// Slave select
    output reg  penable,   
    output wire  pwrite,// Write/read signal
    output reg [7:0] paddr,// Address
    output reg [7:0]pwdata,  
    output reg [7:0]  read_data 
);
assign pwrite=pwrite_in;
localparam
 idle=2'b00,
 setup=2'b01,
access=2'b10;
reg[1:0]state;
reg[1:0]next_state;
 always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= idle;    
        else
            state <= next_state;
    end
   always@(*)begin
   psel      = 0;
   penable   = 0;
   paddr     = 0;
   pwdata    = 0;
   

 case(state)
   idle:begin
    paddr=0;
    pwdata=0;
     if(transfer)
        next_state=setup;
   else 
       state=idle;
        end
        
   setup:begin
   psel=1;
   paddr=paddr_in;
   pwdata=pwdata_in;
   next_state=access;
   end
   access:begin
   penable=1;
   psel=1;
   
   if (pready) begin
                if (pwrite) begin
                    pwdata=pwdata_in;
                end 
                else begin
                    read_data = prdata;
                end
                next_state =(transfer) ? setup :idle;
  
            end
        end
    endcase
end
endmodule
