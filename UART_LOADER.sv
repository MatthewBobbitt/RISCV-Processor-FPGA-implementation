`timescale 1ns / 1ps
// Determines # of instructions
// Assembles each 32 bit instruction
// Stores into IMEM
module UART_LOADER(
    input logic clk,
    input logic rst,
    input logic [7:0] rx_data,
    input logic rx_valid,
    
    output logic imem_write_en, // Enable writing into IMEM
    output logic [7:0] imem_write_addr, // Instruction memory address
    output logic [31:0] imem_write_data, // completed 32 bit instruction
    output logic cpu_rst ,
    output logic load_done, // all instructions uploaded
    output logic load_error // error while loading
    );
    
    logic cpu_running; // = 1 when RUN
    logic [15:0] instruction_count; // # of instructions the computer is uploading (between 1 and 256)
    logic [15:0] instructions_written; // # isntr written to IMEM
    logic [1:0] byte_count; // Determines which of the four bytes being received
    logic [31:0] instruction_buffer; // Temp storage for the four bytes previous to being written to IMEM
    
    localparam [7:0] LOAD = 8'h4C; // Used when typing "L" in C++
    localparam [7:0] RUN = 8'h52; // R
    localparam [7:0] RESET = 8'h58; // X
    
    typedef enum logic [2:0] {
        IDLE,
        COUNT_LOW,
        COUNT_HIGH,
        RECEIVE_DATA,
        WRITE_INSTR
    } state_t;
    
    state_t state;
    
    always_comb begin
        cpu_rst = rst || !cpu_running;
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cpu_running <= 0;
            instruction_count <= 0;
            instructions_written <= 0;
            instruction_buffer <= 0;
            byte_count <= 0;
            imem_write_en <= 0;
            imem_write_addr <= 0;
            imem_write_data <= 0;
            load_done <= 0;
            load_error <= 0;
        end else begin
        
        imem_write_en <= 1'b0;
        
        case (state)
            IDLE: begin
                if (rx_valid) begin
                    if (rx_data == LOAD) begin 
                        cpu_running <= 0; // Stop CPU
                        instruction_count <= 0; // Clear instr count
                        instructions_written <= 0;// Clear # of instructions written
                        instruction_buffer <= 0; // Clear temp storage
                        byte_count <= 0;// Clear byte count
                        load_error <= 0; 
                        load_done <= 0;
                        state <= COUNT_LOW; // Go from load to writing data 
                                            // This makes it possible for CPU to start running by:
                                            // instr_count == instr_written
                    end else if (rx_data == RUN) begin
                        if ((instruction_count != 0) && (instructions_written == instruction_count) && (load_error == 0)) begin
                            // CPU runs if all:
                            // Computer is uploading any # of instr
                            // # of instr in IMEM == instr_count
                            // No load errors
                            cpu_running <= 1;
                        end else begin
                            load_error <= 1; // otherwise: error
                        end
                    end else if (rx_data == RESET) begin
                        cpu_running <= 0;
                        state <= IDLE;
                    end
                end
            end
            COUNT_LOW: begin // Stores lower half of isntr_count
                if (rx_valid) begin
                    instruction_count[7:0] <= rx_data;
                    state <= COUNT_HIGH;
                end
            end
            COUNT_HIGH: begin // Stores upper half of isntr_count
                if (rx_valid) begin
                    instruction_count[15:8] <= rx_data;
                    if (({rx_data, instruction_count[7:0]} > 16'h0000) && 
                    ({rx_data, instruction_count[7:0]} <= 16'h0100)) begin
                    // If the combined bytes are between 1 and 256, proceed
                        state <= RECEIVE_DATA;
                    end else begin
                        load_error <= 1;
                        state <= IDLE;
                    end
                end
            end
            RECEIVE_DATA: begin
                    // Wait for byte
                    // Store byte in correct byte_count[1:0]
                    // When all four bytes arrive, WRITE_INSTR
                    
                    if (rx_valid) begin
                        case(byte_count)
                        2'b00: begin // First byte
                            instruction_buffer[7:0] <= rx_data;
                            byte_count <= 2'b01;
                        end
                        2'b01: begin // Second byte
                            instruction_buffer[15:8] <= rx_data;
                            byte_count <= 2'b10;
                        end
                        2'b10: begin // Third byte
                            instruction_buffer[23:16] <= rx_data;
                            byte_count <= 2'b11;
                        end
                        2'b11: begin // Final byte
                            instruction_buffer[31:24] <= rx_data;
                            byte_count <= 0;
                            state <= WRITE_INSTR;
                        end
                        endcase
                    end
            end
            WRITE_INSTR: begin 
                imem_write_en <= 1; // Enables writing into IMEM
                imem_write_addr[7:0] <= instructions_written[7:0]; // Address written to = instruction # written
                imem_write_data <= instruction_buffer; // Data received from RECEIVE to be written in IMEM
                instructions_written <= instructions_written + 1;
                if (instructions_written + 1 == instruction_count) begin
                    load_done <= 1;
                    state <= IDLE;
                end else begin
                    state <= RECEIVE_DATA;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
        end
    end
    
    
endmodule
