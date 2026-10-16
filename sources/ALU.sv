`timescale 1ns / 1ps


module ALU(
    input logic [31:0] in1,
    input logic [31:0] in2,
    input logic [3:0] op,
    
    output logic [31:0] out
    );
    
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_SLL = 4'b0101;
    localparam ALU_SRL = 4'b0110;
    localparam ALU_SRA = 4'b0111;
    localparam ALU_SLT = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    
    
    always_comb begin
        out = 32'd0;
        case (op)
            ALU_ADD: out = in1 + in2;
            ALU_SUB: out = in1 - in2;
            ALU_AND: out = in1 & in2;
            ALU_OR: out = in1 | in2;
            ALU_XOR: out = in1 ^ in2;
            ALU_SLL: out = in1 << in2[4:0]; //only 5bits used for shift
            ALU_SRL: out = in1 >> in2[4:0];
            ALU_SRA: out = $signed(in1) >>> in2[4:0];
            ALU_SLT: out = $signed(in1) < $signed(in2);
            ALU_SLTU: out = in1 < in2;
        endcase
            
    end
    
endmodule
