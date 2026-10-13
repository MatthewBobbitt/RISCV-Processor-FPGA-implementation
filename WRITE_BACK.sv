`timescale 1ns / 1ps


module WRITE_BACK(
    input logic [31:0] alu_result,
    input logic [31:0] mem,
    input logic [31:0] pc,
    input logic [31:0] imm,
    input logic [1:0] wb_sel, // 2'b00 = alu_result     
                              //2'b01 = mem     
                              //2'b10 = pc      
                              //2'b11 = imm
    
    output logic [31:0] write_data
    );
    
    always_comb begin
        write_data = 0;
    
        case (wb_sel)
            2'b00: begin
                write_data = alu_result;
            end
            2'b01: begin
                write_data = mem;
            end
            2'b10: begin
                write_data = pc + 4; // This needs to be +4 so that return address is the next instruction
            end
            2'b11: begin
                write_data = imm;
            end
        endcase
    end

endmodule
