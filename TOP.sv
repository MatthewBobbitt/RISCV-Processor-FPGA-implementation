`timescale 1ns / 1ps


module TOP(
    input logic clk,
    input logic rst,
    input logic rx,
    output logic tx
    );
    
    logic [31:0] pc; // Current address
    logic [31:0] next_pc; // Next address
    logic pc_write; // Enable PC update
    logic pc_direction; // For branching or jumping
    
    logic [31:0] instruction; // IMEM output
    
    logic [31:0] instr_reg; // Stores current instruction execution
    logic ir_write; // enables instruction register below to be written into
    
    logic imem_write_en;
    logic [7:0] imem_write_addr;
    logic [31:0] imem_write_data;
    
    // INSTRUCTION DECODER SIGNALS (there are a LOT)
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [3:0] alu_op;
    logic alu_src;
    logic alu_a_sel;
    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic [1:0] mem_size;
    logic load_unsigned;
    logic branch;
    logic [2:0] branch_type;
    logic jump;
    logic jump_reg;
    logic [1:0] wb_sel;
    logic ecall;
    logic ebreak;
    logic illegal_instr;
    // Register File
    logic [31:0] read1;
    logic [31:0] read2;
    logic [31:0] write_data;
    logic reg_write_en; // Different than reg_write because:
                        // reg_write tells whether an instruction needs to write to a register.
                        // reg_write_en tells when that write is allowed to happen.
                        
    // Immediate Generator
    logic [31:0] imm;
    // ALU
    logic [31:0] alu_in1;
    logic [31:0] alu_in2;
    logic [31:0] alu_result;
    
    assign alu_in1 = alu_a_sel ? pc : read1;
    assign alu_in2 = alu_src ? imm : read2;
    // DMEM
    logic [31:0] mem_data;
    logic mem_en;
    logic dmem_read;
    logic dmem_write;
    
    assign dmem_read  = mem_en && mem_read;
    assign dmem_write = mem_en && mem_write;
    
    // Branch
    logic branch_confirm;
    
    // Jump
    logic [31:0] jump_target;
    logic jump_confirm;
    // Halt
    logic halted;
    logic [1:0] halt_reason;
    
    // RX TX
    logic [15:0] uart_clocks_per_bit = 16'd868;
    logic [7:0] rx_data;
    logic rx_valid;
    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_busy;
    
    
    PC PC_inst(
        .clk(clk),
        .rst(rst),
        .increment(pc_write && !pc_direction), // increment when not jumping or branching
        .pc_direction(pc_direction && pc_write), // jump or branch when being written to, and when direction is active
        .location(next_pc),
        .address_out(pc)
    );
    
    IMEM instr_mem_inst(
        .clk(clk),
        .address_in(pc),
        .instr_out(instruction),
        .write_en(imem_write_en),
        .write_addr(imem_write_addr),
        .write_data(imem_write_data)
    );
    
    ID id_inst(
        .instr_in(instr_reg),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .alu_a_sel(alu_a_sel),
        .mem_read(mem_read),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned),
        .branch(branch),
        .branch_type(branch_type),
        .jump(jump),
        .jump_reg(jump_reg),
        .wb_sel(wb_sel),
        .ecall(ecall),
        .ebreak(ebreak),
        .illegal_instr(illegal_instr)
    );
    
    Register register_inst(
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_write(reg_write_en),
        .write_data(write_data),
        .read1(read1),
        .read2(read2)
    );
    
    Imm_Gen imm_gen_inst(
        .instr_in(instr_reg),
        .imm_out(imm)
    );
    ALU alu_inst(
        .in1(alu_in1),
        .in2(alu_in2),
        .op(alu_op),
        .out(alu_result)
    );
    DMEM dmem_inst(
        .clk(clk),
        .address(alu_result),
        .write_data(read2),
        .mem_write(dmem_write),
        .mem_read(dmem_read),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned),
        .read_data(mem_data)
    );
    
    BRANCH branch_inst(
        .r1(read1),
        .r2(read2),
        .branch(branch),
        .branch_type(branch_type),
        .branch_confirm(branch_confirm)
    );
    
    JUMP jump_inst(
        .pc(pc),
        .r1(read1),
        .imm(imm),
        .jump(jump),
        .jump_type(jump_reg), // jump_reg = 1 means JALR, so jump_type = jump_reg
        .jump_target(jump_target),
        .jump_confirm(jump_confirm)
    );
    
    WRITE_BACK wb_inst(
        .alu_result(alu_result),
        .mem(mem_data),
        .pc(pc),
        .imm(imm),
        .wb_sel(wb_sel),
        .write_data(write_data)
    );
    
    CTRL_FSM fsm_inst(
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .mem_en(mem_en),
        .reg_write_en(reg_write_en),
        .halted(halted),
        .halt_reason(halt_reason),
        .ecall(ecall),
        .ebreak(ebreak),
        .illegal_instr(illegal_instr)
    );
    
    uart_RX RX_inst(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .clocks_per_bit(uart_clocks_per_bit),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    uart_TX TX_inst(
        .clk(clk),
        .rst(rst),
        .data_in(tx_data),
        .data_valid(tx_valid),
        .clocks_per_bit(uart_clocks_per_bit),
        .tx(tx),
        .busy(tx_busy)
    );
    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            instr_reg <= 0;
        end else if (ir_write) begin
            instr_reg <= instruction;
        end
    end
    
    always_comb begin
        pc_direction = 0;
        next_pc = pc + 4;
        
        if (branch && branch_confirm) begin
            pc_direction = 1;
            next_pc = pc + imm;
        end else if (jump && jump_confirm) begin
            pc_direction = 1;
            next_pc = jump_target;
        end
    end
    

    logic [7:0] pending_data;
    logic pending_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_data <= 8'd0;
            tx_valid <= 1'b0;
            pending_data <= 8'd0;
            pending_valid <= 1'b0;
        end

        else begin
            tx_valid <= 1'b0;
            if (rx_valid) begin
                pending_data <= rx_data;
                pending_valid <= 1'b1;
            end else if (pending_valid && !tx_busy) begin
                tx_data <= pending_data;
                tx_valid <= 1'b1;
                pending_valid <= 1'b0;
            end
        end
    end
    
  
endmodule
