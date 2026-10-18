import riscv_constants::*;

module alu(
    input  logic [2:0] alu_control,    // ALU control signal
    input  logic [31:0] operand1,      // First operand
    input  logic [31:0] operand2,      // Second operand
    output logic [31:0] alu_result,    // Result of ALU operation
    output logic alu_zero              // Zero flag (might be useful for other instructions, however it's not for this subset)
);

    // Perform the operation based on the ALU control signal
    always_comb begin
        case (alu_control)

            ALU_NOP: begin // NOP operation, return 0
                alu_result = 32'b0;
                alu_zero = 1'b0;
            end

            ALU_ADD: begin // Addition
                alu_result = operand1 + operand2;
                alu_zero = (alu_result == 32'b0); // Set to 1 if the result is zero
            end

            ALU_SUB: begin // Subtraction
                alu_result = operand1 - operand2;
                alu_zero = (alu_result == 32'b0);
            end

            ALU_SLT: begin // Set less than
                alu_result = (operand1 < operand2) ? 32'b1 : 32'b0;
                alu_zero = 1'b0;
            end

            ALU_SGE: begin // Set greater than or equal
                alu_result = ($signed(operand1) >= $signed(operand2)) ? 32'b1 : 32'b0;
                alu_zero = 1'b0;
            end

            default: begin // Default case
                alu_result = 32'b0;
                alu_zero = 1'b0;
            end
            
        endcase
    end

endmodule

