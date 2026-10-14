
`timescale 1ns / 1ps

module uart_RX(
    input logic clk,
    input logic rst,
    input logic rx,

    
    input logic [15:0] clocks_per_bit, // Programmable UART timing

    output logic [7:0] data_out,
    output logic data_valid
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
    logic [7:0] rx_data;

    logic rx_meta;
    logic rx_sync;


    always_ff @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clock_count <= 16'd0;
            bit_count <= 3'd0;
            rx_data <= 8'd0;
            data_out <= 8'd0;
            data_valid <= 1'b0;
            active_clocks_per_bit <= 16'd868;
        end else begin
            data_valid <= 1'b0;
            case (state)

                IDLE: begin
                    clock_count <= 16'd0;
                    bit_count <= 3'd0;
                    if (!rx_sync && clocks_per_bit >= 16'd4) begin // Must be >= 4 because cpb/2 - 1 would not work otherwise
                        active_clocks_per_bit <= clocks_per_bit;
                        state <= START;
                    end
                end
                START: begin
                    if (clock_count ==
                        (active_clocks_per_bit / 2) - 1) begin
                        clock_count <= 16'd0;
                        if (!rx_sync) begin
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                DATA: begin
                    if (clock_count == active_clocks_per_bit - 1'b1) begin
                        clock_count <= 16'd0;
                        rx_data[bit_count] <= rx_sync; // Store received bit

                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            state <= STOP;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end

                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                STOP: begin
                    if (clock_count == active_clocks_per_bit - 1'b1) begin
                        clock_count <= 16'd0;
                        if (rx_sync) begin
                            data_out <= rx_data;
                            data_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end
                default: begin
                    state <= IDLE;
                    clock_count <= 16'd0;
                    bit_count <= 3'd0;
                end
            endcase
        end
    end
endmodule
