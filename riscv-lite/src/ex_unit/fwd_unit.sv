module forwarding_unit(
    input  logic CLK,                       
    input  logic RSTn,
    input  logic forward_signal,            // Signal to decide whether to forward
    input  logic instr_valid,               // Flag to indicate valid/not valid instruction
    input  logic [31:0] alu_result_ex_mem,  // ALU result from EX/MEM stage (from instruction n-1)
    input  logic [31:0] operand1,           // Operand1 from Decode Unit (Instruction n)
    output logic [31:0] forwarded_operand1  // Output forwarded operand1
);

    logic [31:0] alu_result_ex_mem_prev;

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            alu_result_ex_mem_prev <= 0;
        end else if (instr_valid) begin
            alu_result_ex_mem_prev <= alu_result_ex_mem;
        end
    end

    // Mux for selecting the operand based on forward_signal
    always_comb begin
        if (forward_signal) begin
            // Forward the alu_result from the EX/MEM stage
            forwarded_operand1 = alu_result_ex_mem_prev;
        end else begin
            // Use the operand from the Decode unit
            forwarded_operand1 = operand1;
        end
    end

endmodule

