`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.08.2025 11:09:10
// Design Name: 
// Module Name: iic_receiver
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


module iic_read_operation(
    input  wire       clk,
    input  wire       rst,
    input  wire       start_signal,
    input  wire [7:0] data,
    input  wire [6:0] slave_addr,
    input  wire [6:0] slave_addr_pointer,
    output reg        scl,
    output reg        sda,
    output reg [7:0] data_read,
    output reg        done_signal

    );
    localparam IDLE=4'b0000,
               START           = 4'b0001,
               SLAVE_ADDRESS_1  = 4'b0010,
               SLAVE_ACK       = 4'b0011,
               ADDRESS_POINTER = 4'b0100,
               ADDRESS_ACK     = 4'b0101,
               WAIT_STATE_1      = 4'b0110,
               SLAVE_ADDRESS_2=4'b0111,
               WAIT_2    = 4'b1000, // wait between pointer and data
               DATA_TX      = 4'b1001,
               MASTER_ACK        = 4'b1010,
               STOP            = 4'b1011; 
               
 reg  [3:0] state;
    reg  [7:0] data_reg;
    reg  [7:0] addr_reg_1; // {7b, R/W=0}
    reg  [7:0] addr_reg_2;           // {7b, R/W=1}
    reg  [6:0] addr_pointer_reg;    // 7-bit pointer
    reg  [3:0] bit_cnt;
    reg  [3:0] wait_cnt;  
    
    // SCL generator
    reg  [15:0] clk_div;
    wire scl_tick = (clk_div == 16'd2);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            
            clk_div <= 16'd0;
            scl     <= 1'b1;
        end else begin
            clk_div <= clk_div + 16'd1;
            if (scl_tick) begin
                scl     <= ~scl;
                clk_div <= 16'd0;
            end
        end
    end
    
    always@(posedge clk or posedge rst)begin               
     if (rst) begin
            state        <= IDLE;
            sda          <= 1'b1;
            done_signal  <= 1'b0;
            bit_cnt      <= 4'd0;
            wait_cnt     <= 4'd0;
            data_reg     <= 8'h00;
            addr_reg_1     <= 8'h00;
            addr_reg_2     <=8'h00;
            addr_pointer_reg <= 7'h00;
        end else begin
            case (state)
            
             IDLE: begin
                    done_signal <= 1'b0;
                    scl <= 1'b1;
                    if (start_signal) begin
                        addr_reg_1<= {slave_addr, 1'b0}; // write op
                        addr_reg_2<={slave_addr,1'b1};//read op
                        addr_pointer_reg  <= slave_addr_pointer;
                        data_reg          <= data;
                        // START: pull SDA low while SCL is (currently) high
                        sda   <= 1'b0;
                        state <= START;
                        
                    end
                end

                START: if (scl_tick) begin
                    state   <= SLAVE_ADDRESS_1;
                    bit_cnt <= 4'd7;
                end

                // -------- SLAVE ADDRESS (8 bits) --------
                SLAVE_ADDRESS_1: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            // Drive next bit while SCL low
                            sda <= addr_reg_1[bit_cnt];
                        end else begin
                            // On SCL high: bit is sampled by slave
                            if (bit_cnt == 0)
                                state <= SLAVE_ACK;
                            else
                                bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // -------- ACK after address --------
                SLAVE_ACK: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            // For a real bus you'd release SDA; here we just hold 0 (sim)
                            sda <= 1'b0;
                        end else begin
                            bit_cnt <= 4'd6; // 7-bit pointer
                            state   <= ADDRESS_POINTER;
                        end
                    end
                end

                // -------- ADDRESS POINTER (7 bits) --------
                ADDRESS_POINTER: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            sda <= addr_pointer_reg[bit_cnt];
                        end else begin
                            if (bit_cnt == 0)
                                state <= ADDRESS_ACK;
                            else
                                bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // -------- ACK after pointer --------
                ADDRESS_ACK: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            sda <= 1'b0; // ACK slot (sim)
                        end else begin
                            wait_cnt <= 4'd0; // start pause
                            state    <= WAIT_STATE_1;
                        end
                    end
                end

                // -------- WAIT between pointer and data --------
                WAIT_STATE_1: begin
                    if (scl_tick) begin
                        if (wait_cnt < 4'd3) begin
                            wait_cnt <= wait_cnt + 1'b1;
                        end else begin
                            wait_cnt <= 4'd0;
                            bit_cnt  <= 4'd7;
                            state    <=SLAVE_ADDRESS_2;
                        end
                    end
                end
                 SLAVE_ADDRESS_2: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            // Drive next bit while SCL low
                            sda <= addr_reg_2[bit_cnt];
                        end else begin
                            // On SCL high: bit is sampled by slave
                            if (bit_cnt == 0)
                                state <= WAIT_2;
                            else
                                bit_cnt <= bit_cnt - 1'b1;
                                wait_cnt <= 4'd0; // reset for next wait
                        end
                    end
                end
                WAIT_2: begin
                    if (scl_tick) begin
                        if (wait_cnt < 4'd3) begin
                            wait_cnt <= wait_cnt + 1'b1;
                        end else begin
                            wait_cnt <= 4'd0;
                            state    <= DATA_TX;
                            bit_cnt<=7;
                        end
                    end
                end
               DATA_TX: begin
                if (scl_tick) begin
                 if (!scl) begin
                     // Release SDA during data phase (simulate Hi-Z)
                    //sda <= 1'b1; 
                     sda<= data[bit_cnt];
                    end else begin // On SCL high, sample SDA from external source
            //sda<= data[bit_cnt];
            if (bit_cnt == 0) begin
                state <= MASTER_ACK;
            end else begin
                bit_cnt <= bit_cnt - 1'b1;
            end
        end
    end
end

                   
                // -------- ACK after data --------
                MASTER_ACK: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            sda <= 1'b0; // ACK slot (sim)
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                // -------- STOP (SDA high while SCL high) --------
                STOP: begin
                    if (scl_tick) begin
                        sda         <= 1'b1;  // STOP
                        done_signal <= 1'b1;
                        state       <= IDLE;
                    end
                end

            endcase
            end
            end
            endmodule