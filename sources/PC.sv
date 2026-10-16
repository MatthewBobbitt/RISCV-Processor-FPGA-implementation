`timescale 1ns / 1ps

module PC(
    input logic clk,
    input logic rst,
    input logic increment,
    input logic pc_direction,
    input logic [31:0] location,
    
    output logic [31:0] address_out
    );

    
    always_ff @(posedge clk) begin
        if (rst) begin
            address_out <= 0;
        end else if (pc_direction) begin //if branching or jumping to new instruction address
            address_out <= location;
        end else if (increment) begin //regular address increment
            address_out <= address_out + 4;
        end
    end
    
    
    
endmodule
