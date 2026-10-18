import riscv_constants::*;

module immediate_generator(
    input  logic [31:0] instruction, // 32-bit instruction
    output logic [31:0] imm_out      // 32-bit sign-extended immediate
);

    logic [6:0] opcode;
    logic [11:0] imm_I;
    logic [11:0] imm_S;
    logic [11:0] imm_SB;
    logic [19:0] imm_U;
    logic [19:0] imm_UJ;

    // Extract opcode
    assign opcode = instruction[6:0];

    // Determine instruction type and sign-extend the immediate based on the instruction type
    always_comb begin
        case(opcode)
            OPCODE_ITYPE1, OPCODE_ITYPE2, OPCODE_ITYPE3: begin // I-Type
                imm_I = instruction[31:20];
                imm_out = {{20{imm_I[11]}}, imm_I};
            end

            OPCODE_STYPE: begin // S-Type
                imm_S = {instruction[31:25], instruction[11:7]};
                imm_out = {{20{imm_S[11]}}, imm_S};
            end

            OPCODE_SBTYPE: begin // SB-Type
                imm_SB = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
                imm_out = {{20{imm_SB[11]}}, imm_SB};
            end

            OPCODE_UTYPE1, OPCODE_UTYPE2: begin // U-Type
                imm_U = instruction[31:12];
                imm_out = {imm_U, 12'b0};
            end

            OPCODE_UJTYPE: begin // UJ-Type
                imm_UJ = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
                imm_out = {{12{imm_UJ[19]}}, imm_UJ};
            end

            default: // Default case for R-Type or unrecognized opcodes
                imm_out = 32'b0;
        endcase
    end

endmodule

