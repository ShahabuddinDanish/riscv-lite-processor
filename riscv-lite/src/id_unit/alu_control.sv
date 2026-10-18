import riscv_constants::*;

module alu_control(
    input  logic [1:0] alu_op,       // ALU operation signal from the control unit
    input  logic [2:0] funct3,       // Funct3 from the decode stage
    input  logic [6:0] funct7,       // Funct7 from the decode stage
    output logic [2:0] alu_control   // ALU control signal
);

    always_comb begin

        case(alu_op)
            2'b00: begin
                alu_control = ALU_NOP;
            end
            2'b01: begin
                if (funct3 == 3'b110) begin
                    alu_control = ALU_SLT;
                end
            end
            2'b10: begin
                if (funct7 == FUNCT7_ADD && funct3 == FUNCT3_ADD) begin
                    alu_control = ALU_ADD;
                end else if (funct7 == FUNCT7_SUB && funct3 == FUNCT3_SUB) begin
                    alu_control = ALU_SUB;
                end else if (funct3 == FUNCT3_ADDI) begin
                    alu_control = ALU_ADD;
                end else if (funct3 == FUNCT3_LW) begin
                    alu_control = ALU_ADD;
                end else if (funct3 == FUNCT3_JALR) begin
                    alu_control = ALU_ADD;
                end else if (funct3 == FUNCT3_SW) begin
                    alu_control = ALU_ADD;
                end else begin              // Default to add operation for AUIPC and JAL instructions
                    alu_control = ALU_ADD;
                end
            end
            2'b11: begin
                if (funct3 == FUNCT3_BGE) begin
                    alu_control = ALU_SGE;
                end
            end
            // default:
            //     alu_control = ALU_NOP;
            // Not necessary to have a default case as all possible cases are covered, however still added for clarity
        endcase
    end

endmodule
