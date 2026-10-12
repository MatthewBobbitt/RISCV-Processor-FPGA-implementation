`timescale 1ns / 1ps

module Imm_Gen(
    input logic [31:0] instr_in,
    output logic [31:0] imm_out
    );
    
    logic [6:0] opcode;
    assign opcode = instr_in[6:0];
    
    always_comb begin
        case (opcode)
            // --------------------------------------------------------------------------------------
            // Arithmetic
            7'b0010011: begin
                // {N{}} is used to repeat bits, {}combines bits
                // This is used to repeat the last bit of instr_in
                //The last bit is the sign bit so we repeat it 20 times + 12 imm bits to make it 32
                // and then combine with the 12 immediate bits [31:20]
                
                imm_out = {{20{instr_in[31]}}, instr_in[31:20]};
            end
            // --------------------------------------------------------------------------------------
            // Load
            7'b0000011: begin
                imm_out = {{20{instr_in[31]}}, instr_in[31:20]};
            end
            // --------------------------------------------------------------------------------------
            // JALR
            7'b1100111: begin
                imm_out = {{20{instr_in[31]}}, instr_in[31:20]};
            end
            // --------------------------------------------------------------------------------------
            // Store type
            7'b0100011: begin
                imm_out = {{{20{instr_in[31]}}, instr_in[31:25]}, instr_in[11:7]};
                // Store type has 2 immediate sections, 31:25 and 11:7
                // This means we combine upper and lower immediate bits
            end
            // --------------------------------------------------------------------------------------
            // Branch type
            7'b1100011: begin
                imm_out = {{19{instr_in[31]}}, instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
                // This layout of bits is due to the weird Branch type instruction layout
            end
            // --------------------------------------------------------------------------------------
            // Load Upper Immediate
            7'b0110111: begin
                // This one is different because we will load 20 bits into the upper half
                // This means 12 bits will be put at then end instead of sign extending
                imm_out = { instr_in[31:12], 12'b0};
            end
            // --------------------------------------------------------------------------------------
            // AUIPC (Add upper immediate to PC)
            7'b0010111: begin
                // Same thing here as with the LUI
                imm_out = {instr_in[31:12], 12'b0};
            end
            // --------------------------------------------------------------------------------------
            // JAL (J-Type)
            7'b1101111: begin
                // Also a funky layout here
                // Remember to keep it at 32 bits
                imm_out = {{11{instr_in[31]}}, instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};
            end
            // --------------------------------------------------------------------------------------
            // Default
            default: imm_out = 32'd0;
        endcase
    end

endmodule



