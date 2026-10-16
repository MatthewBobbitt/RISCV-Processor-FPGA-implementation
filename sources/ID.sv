`timescale 1ns / 1ps
// Understanding ID (Instruction Decoder):
// RISC-V instruction format is - 
// funct7[31:25] 
// rs2(register source 2)[24:20] 
// rs1(register source 1)[19:15] 
// funct3[14:12] 
// rd(destination reg)[11:7] 
// opcode[6:0]
module ID(
    input logic [31:0] instr_in,
    
    output logic [4:0] rs1, 
    output logic [4:0] rs2, 
    output logic [4:0] rd,
    output logic [3:0] alu_op,
    output logic alu_src,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] mem_size, // RISC-V allows for 3 memory access sizes : 8(byte 00), 16(halfword 01), 32(word 10)
    output logic load_unsigned,
    output logic branch,
    output logic [2:0] branch_type,
    output logic jump,
    output logic jump_reg,
    output logic alu_a_sel,
    output logic ecall,
    output logic ebreak,
    output logic illegal_instr,
    output logic [1:0] wb_sel // Selects what gets written into rd
                              // 2'b00 = ALU result
                              // 2'b01 = Data memory
                              // 2'b10 = PC + 4
                              // 2'b11 = Upper Immediate
    );
    
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    
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
    
    assign opcode = instr_in[6:0];
    assign funct3 = instr_in[14:12];
    assign funct7 = instr_in[31:25];
    assign rs1 = instr_in[19:15];
    assign rs2 = instr_in[24:20];
    assign rd = instr_in[11:7];
    
    always_comb begin
        alu_op = 0;
        reg_write = 0;
        alu_src = 0;
        mem_read = 0;
        mem_write = 0;
        mem_size = 2'b10;
        load_unsigned = 0;
        branch = 1'b0;
        branch_type = 3'b000;
        jump = 0;
        wb_sel = 2'b00;
        jump_reg = 0;
        alu_a_sel = 0;
        ecall = 0;
        ebreak = 0;
        illegal_instr = 1;
        
        case (opcode)
            // ---------------------------------------------------------------- 
            // R-Type operations
            7'b0110011: begin
                if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
                    alu_op = ALU_ADD;
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b000 && funct7 == 7'b0100000) begin
                    alu_op = ALU_SUB;
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b111 && funct7 == 7'b0000000) begin
                    alu_op = ALU_AND;
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b110 && funct7 == 7'b0000000) begin
                    alu_op = ALU_OR;
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b100 && funct7 == 7'b0000000) begin
                    alu_op = ALU_XOR;
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b010 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SLT; // Signed Less than
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b011 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SLTU; // Unsigned less than
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SLL; // Shift left logical
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SRL; // Shift right logical
                    reg_write = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
                    alu_op = ALU_SRA; // Shift right arithmetic
                    reg_write = 1;
                    illegal_instr = 0;
                end
            end
            // ---------------------------------------------------------------- 
            // I-Type operations
            7'b0010011: begin
                if (funct3 == 3'b000) begin
                    alu_op = ALU_ADD; // ADDI
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b100) begin
                    alu_op = ALU_XOR; // XORI
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b110) begin
                    alu_op = ALU_OR; // ORI
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b111) begin
                    alu_op = ALU_AND; // ANDI
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b010) begin
                    alu_op = ALU_SLT; // Signed Less than
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b011) begin
                    alu_op = ALU_SLTU; // Unsigned less than
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SLL; // Shift left logical
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
                    alu_op = ALU_SRL; // Shift right logical
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
                    alu_op = ALU_SRA; // Shift right arithmetic
                    reg_write = 1;
                    alu_src = 1;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // Load operations
            7'b0000011: begin
                if (funct3 == 3'b000) begin // LB
                    alu_op = ALU_ADD;
                    mem_read = 1;
                    alu_src = 1;
                    reg_write = 1;
                    wb_sel = 2'b01;
                    mem_size = 2'b00;
                    illegal_instr = 0;
                end else if (funct3 == 3'b001) begin // LH
                    alu_op = ALU_ADD;
                    mem_read = 1;
                    alu_src = 1;
                    reg_write = 1;
                    wb_sel = 2'b01;
                    mem_size = 2'b01;
                    illegal_instr = 0;
                end else if (funct3 == 3'b010) begin // LW
                    alu_op = ALU_ADD;
                    mem_read = 1;
                    alu_src = 1;
                    reg_write = 1;
                    wb_sel = 2'b01;
                    mem_size = 2'b10;
                    illegal_instr = 0;
                end else if (funct3 == 3'b100) begin // LBU
                    alu_op = ALU_ADD;
                    mem_read = 1;
                    alu_src = 1;
                    reg_write = 1;
                    wb_sel = 2'b01;
                    mem_size = 2'b00;
                    load_unsigned = 1;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101) begin // LHU
                    alu_op = ALU_ADD;
                    mem_read = 1;
                    alu_src = 1;
                    reg_write = 1;
                    wb_sel = 2'b01;
                    mem_size = 2'b01;
                    load_unsigned = 1;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // Store operations
            7'b0100011: begin
                if (funct3 == 3'b000) begin // SB
                    alu_op = ALU_ADD;
                    alu_src = 1;
                    mem_read = 0;
                    mem_write = 1;
                    reg_write = 0;
                    load_unsigned = 0;
                    mem_size = 2'b00;
                    illegal_instr = 0;
                end else if (funct3 == 3'b001) begin // SH
                    alu_op = ALU_ADD;
                    alu_src = 1;
                    mem_read = 0;
                    mem_write = 1;
                    reg_write = 0;
                    load_unsigned = 0;
                    mem_size = 2'b01;
                    illegal_instr = 0;
                end else if (funct3 == 3'b010) begin // SW
                    alu_op = ALU_ADD;
                    alu_src = 1;
                    mem_read = 0;
                    mem_write = 1;
                    reg_write = 0;
                    load_unsigned = 0;
                    mem_size = 2'b10;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // Branch operations
            7'b1100011: begin
                if (funct3 == 3'b000) begin // BEQ (Branch if =)
                    alu_op = ALU_SUB;
                    branch = 1;
                    branch_type = 3'b000;
                    illegal_instr = 0;
                end else if (funct3 == 3'b001) begin // BNE
                    alu_op = ALU_SUB;
                    branch = 1;
                    branch_type = 3'b001;
                    illegal_instr = 0;
                end else if (funct3 == 3'b100) begin // BLT (Branch if <)
                    alu_op = ALU_SLT;
                    branch = 1;
                    branch_type = 3'b100;
                    illegal_instr = 0;
                end else if (funct3 == 3'b101) begin // BGE (Branch if >=)
                    alu_op = ALU_SLT;
                    branch = 1;
                    branch_type = 3'b101;
                    illegal_instr = 0;
                end else if (funct3 == 3'b110) begin // BLTU
                    alu_op = ALU_SLTU;
                    branch = 1;
                    branch_type = 3'b110;
                    illegal_instr = 0;
                end else if (funct3 == 3'b111) begin // BGEU
                    alu_op = ALU_SLTU;
                    branch = 1;
                    branch_type = 3'b111;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // Jump and Link operation
            7'b1101111: begin
                // JAL does NOT require alu_op, funct3 or funct7
                jump = 1;
                wb_sel = 2'b10; // PC + 4 will be the return address written
                reg_write = 1;
                illegal_instr = 0;
            end
            // ----------------------------------------------------------------
            // Jump and Link Register operation
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    alu_op = ALU_ADD;
                    jump = 1;
                    reg_write = 1;
                    wb_sel = 2'b10;
                    alu_src = 1;
                    jump_reg = 1;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // Load Upper Immediate (LUI) operation
            7'b0110111: begin
                reg_write = 1;
                wb_sel = 2'b11;
                illegal_instr = 0;
            end
            // ----------------------------------------------------------------
            // Add Upper Immediate to PC (AUIPC) operation
            7'b0010111: begin // First number being added isn't a reg for AUIPC, so we use alu_a_sel
                alu_op = ALU_ADD;
                reg_write = 1;
                alu_src = 1;
                alu_a_sel = 1;
                illegal_instr = 0;
            end
            // ----------------------------------------------------------------
            // FENCE is being left empty, as it won't be needed for Basys 3 simple operations
            7'b0001111: begin
                if (funct3 == 3'b000) begin
                // No operation needed
                illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            // ECALL and EBREAK (Environment call/breakpoint) 
            // Breakpoint used for debugging; stops program at a point
            7'b1110011: begin
                if (instr_in == 32'h00000073) begin // Used when normal instructions can't fulfill a request
                    ecall = 1;
                    illegal_instr = 0;
                end else if (instr_in == 32'h00100073) begin
                    ebreak = 1;
                    illegal_instr = 0;
                end
            end
            // ----------------------------------------------------------------
            
        endcase
    end
    
endmodule
