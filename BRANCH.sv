`timescale 1ns / 1ps

module BRANCH(
    input logic [31:0] r1,
    input logic [31:0] r2,
    input logic branch,
    input logic [2:0] branch_type,
    
    output logic branch_confirm
    );
    
    localparam BEQ  = 3'b000;
    localparam BNE  = 3'b001;
    localparam BLT  = 3'b100;
    localparam BGE  = 3'b101;
    localparam BLTU = 3'b110;
    localparam BGEU = 3'b111;
    
    always_comb begin
    branch_confirm = 0;
    if (branch) begin
        case (branch_type)
            BEQ: begin
                if (r1 == r2) branch_confirm = 1;
            end
            BNE: begin
                if (r1 != r2) branch_confirm = 1;
            end
            BLT: begin
                if ($signed(r1) < $signed(r2)) branch_confirm = 1;
            end
            BGE: begin
                if ($signed(r1) >= $signed(r2)) branch_confirm = 1;
            end
            BLTU: begin
                if (r1 < r2) branch_confirm = 1;
            end
            BGEU: begin
                if (r1 >= r2) branch_confirm = 1;
            end
        endcase
    end
    end
    
    
endmodule
