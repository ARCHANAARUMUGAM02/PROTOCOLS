`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2025 16:26:06
// Design Name: 
// Module Name: i2c_top
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


module tb_i2c_top;

// Testbench signals
reg clk;
reg rst;
reg start_signal;
reg rw;                      // 0 = write, 1 = read
reg [6:0] slave_addr;
reg[6:0]slave_addr_pointer;
reg [7:0] data_in;
wire scl;
wire sda;
wire done;
wire [7:0] data_out;

// SDA pull-up emulation (I2C idle is high)
pullup (sda);

// Instantiate DUT
i2c_protocol_top dut (
    .clk(clk),
    .rst(rst),
    .start_signal(start_signal),
    .rw(rw),
    .slave_addr(slave_addr),
    .slave_addr_pointer(slave_addr_pointer),
    .data_in(data_in),
    .scl(scl),
    .sda(sda),
    .done(done),
    .data_out(data_out)
);

// Generate clock
always #5 clk = ~clk; // 100 MHz clock

// Simple stimulus
initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    start_signal = 0;
    rw = 0;
    slave_addr = 7'h50;  // Example address
    slave_addr_pointer=7'h40;
    data_in = 8'hA5;
    

    // Reset
    #20 rst = 0;

    // --------------------------
    // WRITE operation
    // --------------------------
    #10;
    rw = 0;                 // Write mode
    start_signal = 1;
    #10 start_signal = 0;

    // Wait for write done
    wait(done);
    $display("WRITE COMPLETE: Data Sent = %h", data_in);

    // --------------------------
    // READ operation
    // --------------------------
    #50;
    rw = 1;                 // Read mode
    start_signal = 1;
    #10 start_signal = 0;

    wait(done);
    $display("READ COMPLETE: Data Received = %h", data_out);

    #50;
    $finish;
end
endmodule
