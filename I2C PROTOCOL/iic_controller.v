`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.08.2025 11:25:50
// Design Name: 
// Module Name: iic_controller
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
module iic_write_operation (
    input  wire       clk,
    input  wire       rst,
    input  wire       start_signal,
    input  wire [7:0] data,
    input  wire [6:0] slave_addr,
    input  wire [6:0] slave_addr_pointer,
    output reg        scl,
    output reg        sda,
    output reg        done_signal
);

    // States
    localparam IDLE            = 4'b0000,
               START           = 4'b0001,
               SLAVE_ADDRESS   = 4'b0010,
               SLAVE_ACK       = 4'b0011,
               ADDRESS_POINTER = 4'b0100,
               ADDRESS_ACK     = 4'b0101,
               WAIT_STATE      = 4'b0110, // wait between pointer and data
               SEND_DATA       = 4'b0111,
               WAIT2           = 4'b1000, // wait between data and data-ack
               DATA_ACK        = 4'b1001,
               STOP            = 4'b1010;

    reg  [3:0] state;
    reg  [7:0] data_reg;
    reg  [7:0] addr_reg;            // {7b, R/W=0}
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

    // Main FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            sda          <= 1'b1;
            done_signal  <= 1'b0;
            bit_cnt      <= 4'd0;
            wait_cnt     <= 4'd0;
            data_reg     <= 8'h00;
            addr_reg     <= 8'h00;
            addr_pointer_reg <= 7'h00;
        end else begin
            case (state)

                // -------- IDLE / START --------
                IDLE: begin
                    done_signal <= 1'b0;
                    scl <= 1'b1;
                    if (start_signal) begin
                        addr_reg          <= {slave_addr, 1'b0}; // write op
                        addr_pointer_reg  <= slave_addr_pointer;
                        data_reg          <= data;
                        // START: pull SDA low while SCL is (currently) high
                        sda   <= 1'b0;
                        state <= START;
                        
                    end
                end

                START: if (scl_tick) begin
                    state   <= SLAVE_ADDRESS;
                    bit_cnt <= 4'd7;
                end

                // -------- SLAVE ADDRESS (8 bits) --------
                SLAVE_ADDRESS: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            // Drive next bit while SCL low
                            sda <= addr_reg[bit_cnt];
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
                            state    <= WAIT_STATE;
                        end
                    end
                end

                // -------- WAIT between pointer and data --------
                WAIT_STATE: begin
                    if (scl_tick) begin
                        if (wait_cnt < 4'd3) begin
                            wait_cnt <= wait_cnt + 1'b1;
                        end else begin
                            wait_cnt <= 4'd0;
                            bit_cnt  <= 4'd7;
                            state    <= SEND_DATA;
                        end
                    end
                end

                // -------- DATA byte (8 bits) --------
                SEND_DATA: begin
                    if (scl_tick) begin
                        if (!scl) begin
                            // Put data on SDA while SCL low (meets setup time)
                            sda <= data_reg[bit_cnt];
                        end else begin
                            // After SCL goes high, advance bit counter
                            if (bit_cnt == 0) begin
                                wait_cnt <= 4'd0; // reset for next wait
                                state    <= WAIT2;
                            end else begin
                                bit_cnt <= bit_cnt - 1'b1;
                            end
                        end
                    end
                end

                // -------- WAIT between data and data-ack --------
                WAIT2: begin
                    if (scl_tick) begin
                        if (wait_cnt < 4'd3) begin
                            wait_cnt <= wait_cnt + 1'b1;
                        end else begin
                            wait_cnt <= 4'd0;
                            state    <= DATA_ACK;
                        end
                    end
                end

                // -------- ACK after data --------
                DATA_ACK: begin
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
                    if (scl_tick && scl) begin
                        sda         <= 1'b1;  // STOP
                        done_signal <= 1'b1;
                        state       <= IDLE;
                    end
                end
            endcase
            end
            end
           endmodule