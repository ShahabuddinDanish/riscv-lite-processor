module if_id_pipeline_stage(
    input  logic CLK,                     
    input  logic RSTn,                    // reset signal for pipeline flush
    input  logic enable,                  // Enable signal for pipeline stalls

    input  logic [31:0] pc_in,            // Program counter input from IF stage
    input  logic [31:0] instruction_in,   // Instruction input from IF stage
    input  logic instr_valid_if,

    output logic [31:0] pc_out,           // Program counter output to EX stage
    output logic [31:0] instruction_out,  // Instruction output to ID stage
    output logic instr_valid_id
);

    logic reg_instr_valid;

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            reg_instr_valid <= 1'b0;
        end else if (enable) begin
            reg_instr_valid <= instr_valid_if;
        end
    end

    assign instr_valid_id = reg_instr_valid;

    register_32bit pc_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(pc_in),
        .out(pc_out)
    );

    register_32bit instruction_reg (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .in(instruction_in),
        .out(instruction_out)
    );

endmodule

