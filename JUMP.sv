`timescale 1ns / 1ps


module JUMP(
    input logic [31:0] pc,
    input logic [31:0] r1,
    input logic [31:0] imm,
    input logic jump, // jump enable
    input logic jump_type, // 1'b0 = JAL,     1'b1 = JALR
    
    output logic [31:0] jump_target, // Address being jumped to
    output logic jump_confirm
    );
    
    always_comb begin
        jump_confirm = 0;
        jump_target = 0;
        if (jump) begin
            case (jump_type)
                1'b0: begin // JAL
                    jump_target = pc + imm;
                    jump_confirm = 1;
                end
                1'b1: begin // JALR
                    jump_target = (r1 + imm) & 32'hFFFFFFFE; // sets last bit to 0
                                                             // PC must be in multiples of 4, this won't be guaranteed, but it won't be an odd address
                    jump_confirm = 1;
                end
            endcase
        end 
    end

endmodule
