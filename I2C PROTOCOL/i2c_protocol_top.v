`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2025 16:21:51
// Design Name: 
// Module Name: i2c_protocol_top
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


module i2c_protocol_top (
    input wire clk,
    input wire rst,
    input wire start_signal,
    input wire rw,                     
    input wire [6:0] slave_addr,
    input  wire [6:0] slave_addr_pointer,
    input wire [7:0] data_in,          
    output wire scl,
    inout wire sda,
    output wire done,
    output reg [7:0] data_out         
);

wire done_write, done_read;
wire scl_w, scl_r;
wire sda_w, sda_r;
reg [7:0] mem;

 

// Instantiate write module
iic_write_operation write_inst (
    .clk(clk),
    .rst(rst),
    .start_signal(start_signal && (rw == 0)),
    .slave_addr(slave_addr),
    .slave_addr_pointer(slave_addr_pointer),
    .data(data_in),
    .scl(scl_w),
    .sda(sda_w),
    .done_signal(done_write)
);


iic_read_operation read_inst (
    .clk(clk),
    .rst(rst),
    .start_signal(start_signal && (rw == 1)),
    .slave_addr(slave_addr),
    .slave_addr_pointer(slave_addr_pointer),
    .scl(scl_r),
    .sda(sda_r),
    .done_signal(done_read),
    .data(mem)
);
assign scl = (rw == 0) ? scl_w : scl_r;
assign sda = (rw == 0) ? sda_w : sda_r;  
assign done = (rw == 0) ? done_write : done_read; 
 always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem      <= 8'h00;
            data_out <= 8'h00;
        end else begin
            if (done_write)
                mem <= data_in;
                if(done_read)
            // data_out <= data_out_read;   // ? only assigned here
               data_out <= mem; 
        end
    end

endmodule
