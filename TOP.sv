`timescale 1ns / 1ps


module TOP(
    input logic clk,
    input logic rst
    );
    
    logic [31:0] pc; // Current address
    logic [31:0] next_pc; // Next address
    logic pc_write; // Enable PC update
    logic pc_direction; // For branching or jumping
    
    logic [31:0] instruction; // IMEM output
    
    logic [31:0] instr_reg; // Stores current instruction execution
    logic ir_write; // enables instruction register below to be written into
    
    
    
    PC PC_inst(
        .clk(clk),
        .rst(rst),
        .increment(pc_write && !pc_direction), // increment when not jumping or branching
        .pc_direction(pc_direction && pc_write), // jump or branch when being written to, and when direction is active
        .location(next_pc),
        .address_out(pc)
    );
    
    IMEM instr_mem_inst(
        .clk(clk),
        .address_in(pc),
        .instr_out(instruction)
    );
    
    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            instr_reg <= 0;
        end else if (ir_write) begin
            instr_reg <= instruction;
        end
    end
    
    
endmodule
