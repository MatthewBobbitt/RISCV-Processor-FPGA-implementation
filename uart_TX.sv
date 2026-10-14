`timescale 1ns / 1ps

module uart_TX(
    input logic clk,
    input logic rst,

    input logic [7:0] data_in,
    input logic data_valid,

    
    input logic [15:0] clocks_per_bit, // Programmable UART timing

    output logic tx,
    output logic busy
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state;

    logic [15:0] clock_count;
    logic [15:0] active_clocks_per_bit;

    logic [2:0] bit_count;
    logic [7:0] tx_data;

    // busy = 0: Ready for another byte
    // busy = 1: Currently transmitting

    assign busy = (state != IDLE);

    always_ff @(posedge clk) begin

        if (rst) begin
            state <= IDLE;
            clock_count <= 16'd0;
            bit_count <= 3'd0;
            tx_data <= 8'd0;
            active_clocks_per_bit <= 16'd868;
            tx <= 1'b1;
        end

        else begin

            case (state)

                IDLE: begin
                    tx <= 1'b1;
                    clock_count <= 16'd0;
                    bit_count <= 3'd0;

                    if (data_valid && clocks_per_bit >= 16'd4) begin
                        tx_data <= data_in;
                        active_clocks_per_bit <= clocks_per_bit;
                        tx <= 1'b0;
                        state <= START;
                    end
                end

                START: begin

                    if (clock_count == active_clocks_per_bit - 1'b1) begin
                        clock_count <= 16'd0;
                        
                        tx <= tx_data[0]; // Begin transmitting bit 0
                        state <= DATA;
                    end

                    else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                DATA: begin
                    if (clock_count == active_clocks_per_bit - 1'b1) begin
                        clock_count <= 16'd0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            
                            tx <= 1'b1; // Begin stop bit
                            state <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                            tx <= tx_data[bit_count + 1'b1];
                        end
                    end
                    else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                STOP: begin

                    if (clock_count == active_clocks_per_bit - 1'b1) begin
                        clock_count <= 16'd0;
                        tx <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                default: begin
                    state <= IDLE;
                    clock_count <= 16'd0;
                    bit_count <= 3'd0;
                    tx <= 1'b1;
                end
            endcase
        end
    end
endmodule
