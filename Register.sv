`timescale 1ns / 1ps

module Register(
    input logic clk,
    input logic [4:0] rs1, // Source Reg 1
    input logic [4:0] rs2, // Source Reg 2
    input logic [4:0] rd,  // Destination Register
    input logic reg_write, // Write enable
    input logic [31:0] write_data, // Data being written
    
    output logic [31:0] read1, // Data from Reg 1 being read
    output logic [31:0] read2  // Data from Reg 2 being read
    );
    logic [31:0] registers [0:31];
    
    // Reg0 will always contain the value 0
    // All other 31 registers will be general purpose
    assign read1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1]; // if rs1 = 0; x0 = 0
    assign read2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];
    
    always_ff @(posedge clk) begin
        if (reg_write && rd != 5'd0) begin // Doesn't write if R0 = 0
            registers[rd] <= write_data;
        end
    end
    
  
endmodule
