import riscv_constants::*;

module control_unit(
    input  logic [6:0] opcode,             // Opcode from the decode unit
    input  logic [2:0] funct3,             // Funct3 from the decode unit (used for I, S, SB, R type instructions)
    input  logic [6:0] funct7,             // Funct7 from the decode unit (used for R type instructions)
    
    output logic branch,                   // Branch signal (used for checking conditional branches)
    output logic jump,                     // Jump signal (used to indicate a jump)
    output logic jal,                      // JAL signal (used to indicate a JAL instruction)
    output logic jalr,                     // JALR signal (used to indicate a JALR instruction)
    output logic alu_src1,                 // ALU source signal for immediate and rs2 
    output logic alu_src2,                 // ALU source signal for program counter and rs1
    output logic [1:0] alu_op,             // ALU operation signal
    output logic mem_to_reg,               // Memory to Register Load signal
    output logic mem_read,                 // Memory Read signal
    output logic mem_write,                // Memory Write signal
    output logic reg_write                 // Register Write signal
);

    always_comb begin

        // Decode the instruction based on opcode and function codes
        case (opcode)
            OPCODE_RTYPE: begin
                alu_src1 <= 0;      // ALU source 1 set to register file
                alu_src2 <= 0;      // ALU source 2 set to register file
                mem_to_reg <= 0;    // ALU output selected for register writeback stage
                reg_write <= 1;     // Write result back to register file
                mem_read <= 0;      // Disable memory read operation
                mem_write <= 0;     // Disable memory write operation
                branch <= 0;        // No branch operation
                jump <= 0;          // No jump operation
                jal <= 0;
                jalr <= 0;

                // Determine ALU operation based on funct7 and funct3
                if (funct7 == FUNCT7_ADD && funct3 == FUNCT3_ADD) begin
                    alu_op <= 2'b10;  // ALU_ADD
                end else if (funct7 == FUNCT7_SUB && funct3 == FUNCT3_SUB) begin
                    alu_op <= 2'b10;  // ALU_SUB
                end
            end

            OPCODE_ITYPE1: begin
                if (funct3 == FUNCT3_ADDI) begin
                    alu_src1 <= 1;      // ALU source set to immediate value
                    alu_src2 <= 0;
                    alu_op <= 2'b10;    // ALU operation for ADD
                    mem_to_reg <= 0;    // ALU output selected for register writeback stage
                    reg_write <= 1;     // Enable writing result back to register file
                    mem_read <= 0;      // Disable memory read operation
                    mem_write <= 0;     // Disable memory write operation
                    branch <= 0;        // No branch operation
                    jump <= 0;          // No jump operation
                    jal <= 0;
                    jalr <= 0;
                end
            end

            OPCODE_ITYPE2: begin
                if (funct3 == FUNCT3_LW) begin
                    alu_src1 <= 1;
                    alu_src2 <= 0;
                    alu_op <= 2'b10;
                    mem_to_reg <= 1;    // Memory output selected for register writeback stage
                    reg_write <= 1;
                    mem_read <= 1;      // Enable memory read operation
                    mem_write <= 0;
                    branch <= 0;
                    jump <= 0;
                    jal <= 0;
                    jalr <= 0;
                end
            end

            OPCODE_ITYPE3: begin
                if (funct3 == FUNCT3_JALR) begin
                    alu_src1 <= 1;
                    alu_src2 <= 0;
                    alu_op <= 2'b10;    // ADD operation for JALR to add rs1 to immediate
                    mem_to_reg <= 0;
                    reg_write <= 1;     // Set to 1 to write return address
                    mem_read <= 0;
                    mem_write <= 0;
                    branch <= 0;
                    jump <= 1;          // Jump operation
                    jal <= 0;
                    jalr <= 1;
                end
            end

            OPCODE_STYPE: begin     // S-Type instructions
                if (funct3 == FUNCT3_SW) begin
                    alu_src1 <= 1;
                    alu_src2 <= 0;
                    alu_op <= 2'b10;
                    mem_to_reg <= 0;
                    reg_write <= 0;     // Enable writing result back to register file
                    mem_read <= 0;
                    mem_write <= 1;     // Enable memory write operation
                    branch <= 0;
                    jump <= 0;
                    jal <= 0;
                    jalr <= 0;
                end
            end

            OPCODE_SBTYPE: begin    // SB-Type instructions
                if (funct3 == FUNCT3_BLTU) begin
                    alu_src1 <= 0;       
                    alu_src2 <= 0;
                    alu_op <= 2'b01;    // ALU operation for SLT
                    mem_to_reg <= 0;
                    reg_write <= 0;
                    mem_read <= 0;
                    mem_write <= 0;
                    branch <= 1;        // Branch Operation
                    jump <= 0;
                    jal <= 0;
                    jalr <= 0;
                end

                if (funct3 == FUNCT3_BGE) begin
                    alu_src1 <= 0;
                    alu_src2 <= 0;
                    alu_op <= 2'b11;    // ALU operation for SGE
                    mem_to_reg <= 0;
                    reg_write <= 0;
                    mem_read <= 0;
                    mem_write <= 0;
                    branch <= 1;
                    jump <= 0;
                    jal <= 0;
                    jalr <= 0;
                end
            end

            OPCODE_UTYPE1: begin    // AUIPC
                alu_src1 <= 1;
                alu_src2 <= 1;          // ALU source 2 set to program counter
                alu_op <= 2'b10;
                mem_to_reg <= 0;
                reg_write <= 1;
                mem_read <= 0;  
                mem_write <= 0;
                branch <= 0;
                jump <= 0;  
                jal <= 0;
                jalr <= 0;
            end

            OPCODE_UTYPE2: begin    // LUI
                alu_src1 <= 1;
                alu_src2 <= 0;
                alu_op <= 2'b10;        // ALU ADD (to forward immediate)
                mem_to_reg <= 0;
                reg_write <= 1;
                mem_read <= 0;
                mem_write <= 0;
                branch <= 0;
                jump <= 0;
                jal <= 0;
                jalr <= 0;
            end

            OPCODE_UJTYPE: begin    // JAL
                alu_src1 <= 1;
                alu_src2 <= 0;
                alu_op <= 2'b00;    // ALU NOP for JAL
                mem_to_reg <= 0;
                reg_write <= 1;
                mem_read <= 0;
                mem_write <= 0;
                branch <= 0;
                jump <= 1;              // Jump operation
                jal <= 1;
                jalr <= 0;
            end

            default: begin
                // enable signals for different stages here can be turned off
                alu_src1 <= 0;          // Default to not using the immediate value for the ALU
                alu_src2 <= 0;          // Default to not using the program counter for the ALU
                alu_op <= 2'b00;        // Set to default, non-operational ALU code
                mem_to_reg <= 0;        // Disable memory to register file operations
                reg_write <= 0;         // Disable writing to the register file
                mem_read <= 0;          // Disable memory read
                mem_write <= 0;         // Disable memory write
                branch <= 0;            // Disable branching
                jump <= 0;              // Disable jumping
                jal <= 0;
                jalr <= 0;
            end
        endcase
    end

endmodule
