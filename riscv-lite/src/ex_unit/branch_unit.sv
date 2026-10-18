module branch_unit(
    input  logic [31:0] pc,             // Current program counter (from Fetch Unit)
    input  logic [31:0] imm,            // Immediate value (from Decode Unit)
    input  logic branch,                // Branch signal (from Decode Unit)
    input  logic jump,                  // Jump signal (from Decode Unit)
    input  logic jal,                   // JAL signal (from Decode Unit)
    input  logic jalr,                  // JALR signal (from Decode Unit)
    input  logic [31:0] alu_result,     // Result from ALU
    
    output logic [31:0] new_pc,         // New program counter value (to Fetch Unit)
    output logic branch_jump_taken      // Flag to indicate branch/jump taken (to Fetch Unit)
);

always_comb begin

    // Handle branch conditions
    if (branch == 1 && jump == 0) begin
        if (alu_result == 32'd1) begin      // Check LSB of alu_result
            // Branch condition met (either BLTU or BGE)
            branch_jump_taken = 1'b1;
            new_pc = pc + (imm << 1); // Left shift imm by 1 bit and add to pc
        end else begin
            // Branch condition not met
            branch_jump_taken = 1'b0;
            new_pc = 32'b0;
        end
    end else if (branch == 0 && jump == 0) begin
        // No branch performed
        branch_jump_taken = 1'b0;
        new_pc = 32'b0;
    end

    if (jump == 1 && branch == 0) begin
        if (jal) begin
            // JAL instruction
            branch_jump_taken = 1;
            new_pc = pc + (imm << 1); // Left shift imm by 1 bit and add to pc
        end else if (jalr) begin
            // JALR instruction
            branch_jump_taken = 1;
            new_pc = alu_result + (imm & ~1); // Set LSB of ALU result to 0
        end
    end else if (jump == 0 && branch == 0) begin
        // No jump performed
        branch_jump_taken = 0;
        new_pc = 32'b0;
    end
end

endmodule

