`timescale 1ns / 1ps

module IMEM(
    input logic clk,
    input logic [31:0] address_in,
    input logic write_en,
    input logic [7:0] write_addr,
    input logic [31:0] write_data,
    
    output logic [31:0] instr_out
    );

    logic [31:0] memory [0:255];    // 256 instructions, 32 bits each

    initial begin
        for (integer i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013; // sets all instructions to NOP
                                      // Loader will overwrite this

        
    end

    always_ff @(posedge clk) begin
        instr_out <= memory[address_in[9:2]];
    end

    always_ff @(posedge clk) begin
        if (write_en)
            memory[write_addr] <= write_data;
    end

endmodule
