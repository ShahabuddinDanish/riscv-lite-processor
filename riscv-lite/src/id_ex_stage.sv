module id_ex_pipeline_stage(
    input  logic CLK,
    input  logic RSTn,              // reset signal for pipeline flush
    input  logic enable,            // Enable signal for pipeline stall

    // Inputs from Fetch Unit
    input  logic [31:0] pc,
    
    // Inputs from Decode Unit
    input  logic [31:0] read_data1,
    input  logic [31:0] read_data2,
    input  logic [31:0] imm,
    input  logic [2:0] alu_control,
    input  logic alu_src1,
    input  logic alu_src2,
    input  logic branch,
    input  logic jump,
    input  logic jal,
    input  logic jalr,
    input  logic mem_to_reg,
    input  logic mem_read,
    input  logic mem_write,
    input  logic reg_write,
    input  logic [4:0] rd,
    input  logic forward_signal,
    input  logic instr_valid,

    // Outputs to Execution Unit
    output logic [31:0] operand1, operand2, ex_imm,
    output logic [2:0] ex_alu_control,
    output logic ex_alu_src1, ex_alu_src2,
    output logic ex_branch, ex_jump, ex_jal, ex_jalr,
    output logic [31:0] ex_pc,
    output logic ex_forward_signal,
    output logic ex_instr_valid,

    // Outputs to Memory Unit
    output logic ex_mem_to_reg, ex_mem_read, ex_mem_write,
    
    // Outputs to Write-back Unit
    output logic ex_reg_write,
    output logic [4:0] ex_rd
);

    // Register declaration for holding ID stage outputs
    logic [2:0]  alu_control_reg;
    logic [4:0]  rd_reg;
    
    logic alu_src1_reg;
    logic alu_src2_reg;
    logic branch_reg;
    logic jump_reg;
    logic jal_reg;
    logic jalr_reg;
    logic mem_to_reg_reg;
    logic mem_read_reg;
    logic mem_write_reg;
    logic reg_write_reg;
    logic forward_signal_reg;
    logic instr_valid_reg;

    register_32bit pc_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(pc),
        .out(ex_pc)
    );

    register_32bit operand1_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(read_data1),
        .out(operand1)
    );

    register_32bit operand2_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(read_data2),
        .out(operand2)
    );

    register_32bit imm_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(imm),
        .out(ex_imm)
    );

    // Register update logic
    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            alu_control_reg <= 3'b0;
            rd_reg <= 5'b0;
            alu_src1_reg <= 0;
            alu_src2_reg <= 0;
            branch_reg <= 0;
            jump_reg <= 0;
            jal_reg <= 0;
            jalr_reg <= 0;
            mem_to_reg_reg <= 0;
            mem_read_reg <= 0;
            mem_write_reg <= 0;
            reg_write_reg <= 0;
            forward_signal_reg <= 0;
            instr_valid_reg <= 0;
        end else if (enable) begin
            alu_control_reg <= alu_control;
            rd_reg <= rd;
            alu_src1_reg <= alu_src1;
            alu_src2_reg <= alu_src2;
            branch_reg <= branch;
            jump_reg <= jump;
            jal_reg <= jal;
            jalr_reg <= jalr;
            mem_to_reg_reg <= mem_to_reg;
            mem_read_reg <= mem_read;
            mem_write_reg <= mem_write;
            reg_write_reg <= reg_write;
            forward_signal_reg <= forward_signal;
            instr_valid_reg <= instr_valid;
        end
    end

    // Output assignment
    assign ex_alu_control = alu_control_reg;
    assign ex_alu_src1 = alu_src1_reg;
    assign ex_alu_src2 = alu_src2_reg;
    assign ex_branch = branch_reg;
    assign ex_jump = jump_reg;
    assign ex_jal = jal_reg;
    assign ex_jalr = jalr_reg;
    assign ex_mem_to_reg = mem_to_reg_reg;
    assign ex_mem_read = mem_read_reg;
    assign ex_mem_write = mem_write_reg;
    assign ex_reg_write = reg_write_reg;
    assign ex_rd = rd_reg;
    assign ex_forward_signal = forward_signal_reg;
    assign ex_instr_valid = instr_valid_reg;

endmodule
