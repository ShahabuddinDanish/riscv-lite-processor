module execution_unit(
    input  logic CLK,
    input  logic RSTn,

    // Inputs from Decode Unit
    input  logic [31:0] operand1,       // First operand from Register File
    input  logic [31:0] operand2,       // Second operand from Register File
    input  logic [31:0] imm,            // Immediate value
    input  logic [2:0] alu_control,     // ALU control signal
    input  logic alu_src1,              // ALU source signal 1 for second operand
    input  logic alu_src2,              // ALU source signal 2 for first operand
    input  logic branch,                // Branch signal
    input  logic jump,                  // Jump signal
    input  logic jal,                   // JAL signal
    input  logic jalr,                  // JALR signal

    // Input from Fetch Unit
    input  logic [31:0] pc,             // Program Counter
    input  logic instr_valid,           // Valid instruction flag

    // Inputs from EX/MEM stage (for forwarding)
    input  logic [31:0] alu_result_ex_mem,  // ALU result from EX/MEM stage (for instruction n-1)
    input  logic forward_signal,            // Forwarding signal from HDU

    // Outputs to next stages
    output logic [31:0] alu_result,     // Result of ALU operation (to Mem Unit)
    output logic [31:0] new_pc,         // New program counter value (to Fetch Unit)
    output logic branch_jump_taken,     // Flag for branch/jump taken (to Fetch Unit)
    output logic [31:0] return_address  // Return address for JAL and JALR (to Write-back Unit)
);

    logic [31:0] mux_output_operand1;
    logic [31:0] mux_output_operand2;
    logic [31:0] forwarded_operand1;    // Output from forwarding unit

    // Instantiate forwarding unit
    forwarding_unit fwd_unit(
        .CLK(CLK),
        .RSTn(RSTn),
        .forward_signal(forward_signal),
        .instr_valid(instr_valid),
        .alu_result_ex_mem(alu_result),
        .operand1(operand1),
        .forwarded_operand1(forwarded_operand1)
    );

    // Mux for selecting the first ALU operand
    mux2to1 operand1_mux(
        .select(alu_src2),
        .in0(forwarded_operand1),   // Operand from Forwarding Unit
        .in1(pc),                   // Program Counter
        .out(mux_output_operand1)
    );

    // Mux for selecting the second ALU operand
    mux2to1 operand2_mux(
        .select(alu_src1),
        .in0(operand2),      // Operand from Register File
        .in1(imm),           // Immediate value
        .out(mux_output_operand2)
    );

    // Instantiating the ALU
    alu alu_unit(
        .alu_control(alu_control),
        .operand1(mux_output_operand1), // Output of operand 1 Mux
        .operand2(mux_output_operand2), // Output of operand 2 Mux
        .alu_result(alu_result),
        .alu_zero()                     // Not used used in this instruction subset
    );

    // Instance of Branch Unit
    branch_unit branch_unit(
        .pc(pc),
        .imm(imm),
        .branch(branch),
        .jump(jump),
        .jal(jal),
        .jalr(jalr),
        .alu_result(alu_result),
        .new_pc(new_pc),
        .branch_jump_taken(branch_jump_taken)
    );

    // Dedicated logic for computing return address (PC + 4), can be integrated into the ALU in future
    always_comb begin
        if (jal || jalr) begin
            return_address = pc + 32'd4;
        end else begin
            return_address = 32'd0; // Default to 0 when not JAL or JALR
        end
    end

endmodule

