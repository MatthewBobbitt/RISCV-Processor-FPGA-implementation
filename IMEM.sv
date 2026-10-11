`timescale 1ns / 1ps

module IMEM(
    input logic clk,
    input logic [31:0] address_in,
    output logic [31:0] instr_out
    );
    
    logic [31:0] memory [0:255]; // 32 bit memory with 256 locations

    initial begin
        $readmemh("program.mem", memory);
    end
    always_ff @(posedge clk) begin
        instr_out <= memory[address_in[9:2]]; // Use address bits [9:2] to select one of 256 instructions
    end
    
endmodule
