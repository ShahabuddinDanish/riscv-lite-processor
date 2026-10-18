module mem_wb_pipeline_stage(
    input  logic CLK,
    input  logic RSTn,              // Reset signal for pipeline flush
    input  logic enable,            // Enable signal for pipeline stall

    // Inputs from MEM stage
    input logic [31:0] mem_mem_read_data,
    input logic mem_mem_to_reg,
    input logic [31:0] mem_alu_result,
    input logic [31:0] mem_return_address,
    input logic [4:0] mem_write_addr,
    input logic mem_reg_write,
    input logic mem_jal,
    input logic mem_jalr,

    // Outputs to WB stage
    output logic [31:0] wb_mem_read_data,
    output logic wb_mem_to_reg,
    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_return_address,
    output logic [4:0] wb_write_addr,
    output logic wb_reg_write,
    output logic wb_jal,
    output logic wb_jalr
);

    // Internal Registers
    logic reg_mem_to_reg;
    logic [4:0] reg_write_addr;
    logic reg_reg_write;
    logic reg_jal;
    logic reg_jalr;

    register_32bit mem_read_data_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(mem_mem_read_data),
        .out(wb_mem_read_data)
    );

    register_32bit alu_result_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(mem_alu_result),
        .out(wb_alu_result)
    );

    register_32bit return_address_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(mem_return_address),
        .out(wb_return_address)
    );

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            reg_mem_to_reg <= 1'b0;
            reg_write_addr <= 5'd0;
            reg_reg_write <= 1'b0;
            reg_jal <= 1'b0;
            reg_jalr <= 1'b0;
        end else if (enable) begin
            reg_mem_to_reg <= mem_mem_to_reg;
            reg_write_addr <= mem_write_addr;
            reg_reg_write <= mem_reg_write;
            reg_jal <= mem_jal;
            reg_jalr <= mem_jalr;
        end
    end

    // Assign outputs to the internal registers
    assign wb_mem_to_reg = reg_mem_to_reg;
    assign wb_write_addr = reg_write_addr;
    assign wb_reg_write = reg_reg_write;
    assign wb_jal = reg_jal;
    assign wb_jalr = reg_jalr;

endmodule

