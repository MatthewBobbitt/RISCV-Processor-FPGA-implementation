`timescale 1ns / 1ps

module DMEM(
    input logic clk,
    input logic [31:0] address,
    input logic [31:0] write_data,
    input logic mem_write,
    input logic mem_read,
    input logic [1:0] mem_size, // 00 = 8 bits     01 = 16 bits     11 = 32 bits
    input logic load_unsigned,

    output logic [31:0] read_data
    );
    // Create memory array 
    // Store 8,16,32 bits depending on mem size and mem_write
    // Read 8,16,32 depending on mem_read and then sign extend by using {{N{}},   }

    logic [31:0] memory [0:31];

    always_ff @(posedge clk) begin
        if (mem_write) begin
           case (mem_size)
               // ----------------------------------------------------------------------------------------------
               2'b00: begin // Write 8 bits
                    case (address[1:0])
                        2'b00: begin // Byte 0 (8 bits) out of 3 Bytes
                            memory[address[6:2]][7:0] <= write_data[7:0]; //address[6:2] stores the word
                        end
                        2'b01: begin // Byte 1 (9-16 bits)
                            memory[address[6:2]][15:8] <= write_data[7:0];
                        end
                        2'b10: begin // Byte 2 (17-24 bits)
                            memory[address[6:2]][23:16] <= write_data[7:0];
                        end
                        2'b11: begin // Byte 3 (25-32 bits)
                            memory[address[6:2]][31:24] <= write_data[7:0];
                        end
                    endcase
               end
               // ----------------------------------------------------------------------------------------------
               2'b01: begin // Write 16 bits
                    case (address[1])
                        1'b0: begin // Writing first half 16 bits
                            memory[address[6:2]][15:0] <= write_data[15:0]; 
                        end
                        1'b1: begin // Writing first half 16 bits
                            memory[address[6:2]][31:16] <= write_data[15:0]; 
                        end
                    endcase
               end
               // ----------------------------------------------------------------------------------------------
               2'b10: begin
                    memory[address[6:2]] <= write_data[31:0];
               end
           endcase
           // ----------------------------------------------------------------------------------------------
           // Load Instruction
        end else if (mem_read) begin
            if (!load_unsigned || mem_size == 2'b10) begin
                case (mem_size)
                    2'b00: begin // Load singular byte
                        case (address[1:0])
                            2'b00: begin
                                // Load first quarter of bytes (8/32 bits)
                                read_data <= {{24{memory[address[6:2]][7]}}, memory[address[6:2]][7:0]};
                            end
                            2'b01: begin
                                // Load second quarter of bytes ( 9->16/32 bits)
                                read_data <= {{24{memory[address[6:2]][15]}}, memory[address[6:2]][15:8]};
                            end
                            2'b10: begin
                                // Load third quarter of bytes ( 17->24/32 bits)
                                read_data <= {{24{memory[address[6:2]][23]}}, memory[address[6:2]][23:16]};
                            end
                            2'b11: begin
                                // Load fourth quarter of bytes ( 25->32/32 bits)
                                read_data <= {{24{memory[address[6:2]][31]}}, memory[address[6:2]][31:24]};
                            end
                        endcase
                    end
                    // ----------------------------------------------------------------------------------------------
                    2'b01: begin // Load Halfword
                        case (address[1])
                            1'b0: begin
                                // Load first half word (16/32)
                                read_data <= {{16{memory[address[6:2]][15]}}, memory[address[6:2]][15:0]};
                            end
                            1'b1: begin
                                // Load second half word (bits 17->32)
                                read_data <= {{16{memory[address[6:2]][31]}}, memory[address[6:2]][31:16]};
                            end
                        endcase
                    end
                    // ----------------------------------------------------------------------------------------------
                    2'b10: begin // Load word
                         read_data <= memory[address[6:2]];
                    end
                endcase
                // ----------------------------------------------------------------------------------------------
            end else if (load_unsigned) begin
                case (mem_size)
                    2'b00: begin // Load singular byte UNSIGNED
                        case (address[1:0])
                            2'b00: begin
                                // Load first quarter of bytes (8/32 bits)
                                read_data <= {24'b0, memory[address[6:2]][7:0]};
                            end
                            2'b01: begin
                                // Load second quarter of bytes ( 9->16/32 bits)
                                read_data <= {24'b0, memory[address[6:2]][15:8]};
                            end
                            2'b10: begin
                                // Load third quarter of bytes ( 17->24/32 bits)
                                read_data <= {24'b0, memory[address[6:2]][23:16]};
                            end
                            2'b11: begin
                                // Load fourth quarter of bytes ( 25->32/32 bits)
                                read_data <= {24'b0, memory[address[6:2]][31:24]};
                            end
                        endcase
                    end
                    // ----------------------------------------------------------------------------------------------
                    2'b01: begin // Load Halfword
                        case (address[1])
                            1'b0: begin
                                // Load first half word (16/32)
                                read_data <= {16'b0, memory[address[6:2]][15:0]};
                            end
                            1'b1: begin
                                // Load second half word (bits 17->32)
                                read_data <= {16'b0, memory[address[6:2]][31:16]};
                            end
                        endcase
                    end
                    // ----------------------------------------------------------------------------------------------
                    // LW unsigned is not needed
                endcase
            end
        end
    end
endmodule
