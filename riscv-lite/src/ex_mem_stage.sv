module ex_mem_pipeline_stage (
    input  logic CLK,
    input  logic RSTn,              // reset signal for pipeline flush
    input  logic enable,            // enable signal for pipeline stall

    // Inputs from Execute Unit
    input  logic branch_jump_taken_ex,
    input  logic [31:0] pc_ex,
    input  logic [31:0] alu_result_ex,
    input  logic [31:0] operand2_ex,
    input  logic [31:0] return_address_ex,

    // Inputs from Decode Unit
    input  logic        mem_read_ex,
    input  logic        mem_write_ex,
    input  logic        jal_ex,
    input  logic        jalr_ex,
    input  logic [4:0]  write_addr_ex,
    input  logic        reg_write_ex,
    input  logic        mem_to_reg_ex,

    // Outputs to Fetch Unit
    output logic [31:0] pc_mem,
    output logic branch_jump_taken_mem,

    // Outputs to Memory Unit
    output logic [31:0] alu_result_mem,
    output logic [31:0] operand2_mem,
    output logic        mem_read_mem,
    output logic        mem_write_mem,

    // Outputs to Write-back Unit
    output logic [31:0] return_address_mem,
    output logic        jal_mem,
    output logic        jalr_mem,
    output logic [4:0]  write_addr_mem,
    output logic        reg_write_mem,
    output logic        mem_to_reg_mem

);

    // Pipeline registers
    logic branch_jump_taken_reg, jal_reg, jalr_reg, reg_write_reg, mem_to_reg_reg;
    logic [4:0] write_addr_reg;
    logic mem_read_reg, mem_write_reg;

    register_32bit pc_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(pc_ex),
        .out(pc_mem)
    );

    register_32bit alu_result_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(alu_result_ex),
        .out(alu_result_mem)
    );

    register_32bit operand2_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(operand2_ex),
        .out(operand2_mem)
    );

    register_32bit return_address_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(return_address_ex),
        .out(return_address_mem)
    );

    // Update pipeline registers
    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            branch_jump_taken_reg <= 1'b0;
            jal_reg               <= 1'b0;
            jalr_reg              <= 1'b0;
            write_addr_reg        <= 5'b0;
            reg_write_reg         <= 1'b0;
            mem_read_reg          <= 1'b0;
            mem_write_reg         <= 1'b0;
            mem_to_reg_reg        <= 1'b0;
        end else if (enable) begin
            branch_jump_taken_reg <= branch_jump_taken_ex;
            jal_reg               <= jal_ex;
            jalr_reg              <= jalr_ex;
            write_addr_reg        <= write_addr_ex;
            reg_write_reg         <= reg_write_ex;
            mem_read_reg          <= mem_read_ex;
            mem_write_reg         <= mem_write_ex;
            mem_to_reg_reg        <= mem_to_reg_ex;
        end
    end

    // Assign outputs to pipeline registers
    assign branch_jump_taken_mem = branch_jump_taken_reg;
    assign jal_mem               = jal_reg;
    assign jalr_mem              = jalr_reg;
    assign write_addr_mem        = write_addr_reg;
    assign reg_write_mem         = reg_write_reg;
    assign mem_read_mem          = mem_read_reg;
    assign mem_write_mem         = mem_write_reg;
    assign mem_to_reg_mem        = mem_to_reg_reg;

endmodule

