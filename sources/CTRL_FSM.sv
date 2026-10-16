`timescale 1ns / 1ps


module CTRL_FSM(
    input logic clk,
    input logic rst,
    
    input logic mem_read,
    input logic mem_write, 
    input logic reg_write,
    input logic branch,
    input logic jump,
    
    output logic pc_write,
    output logic ir_write,
    output logic mem_en,
    output logic reg_write_en
    );
    
    typedef enum logic [2:0] {
        FETCH,
        FETCH_WAIT, // Used to account for clock edge timing issues
        DECODE,
        EXECUTE,
        MEMORY,
        WRITEBACK
    } state_t;
    
    state_t state, next_state;
    
    
    // sequential logic to update state
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= FETCH; // PC module
        end else begin
            state <= next_state;
        end
    end
    
    
    // combinational logic to determine next state
    always_comb begin
        next_state = state;
        pc_write = 0;
        ir_write = 0;
        mem_en = 0;
        reg_write_en = 0;
        case (state)
            FETCH: begin
                next_state = FETCH_WAIT; 
            end
            FETCH_WAIT: begin
                ir_write = 1;
                next_state = DECODE; // Instruction Decoder module
            end
            DECODE: begin
                next_state = EXECUTE; // determine read, write, reg write, or back to fetch
            end
            EXECUTE: begin
                if (mem_read || mem_write) begin
                    next_state = MEMORY;
                end else if (branch) begin
                    pc_write = 1;
                    next_state = FETCH; // Does not save return address
                end else if (jump) begin
                    next_state = WRITEBACK; // Save return address, so go to wb;    Don't pc_write until WB
                end else if (reg_write) begin // reg_write needs to be the last to be checked
                                              // This is because JAL and JALR both have reg_write and jump = 1
                    next_state = WRITEBACK;
                end else begin
                    pc_write = 1;
                    next_state = FETCH;
                end
            end
            MEMORY: begin
                mem_en = 1;
                if (mem_read) begin
                    next_state = WRITEBACK;
                end else begin
                    pc_write = 1;
                    next_state = FETCH;
                end
            end
            WRITEBACK: begin
                reg_write_en = reg_write;
                pc_write = 1;
                next_state = FETCH;
            end
            default: begin
                next_state = FETCH;
            end
        endcase
    end

    
endmodule
