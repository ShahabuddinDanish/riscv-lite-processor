import riscv_constants::*;

module decode_unit(
    input  logic [31:0] instruction,  // Instruction (from Fetch Unit)
    output logic [4:0] rd,            // Destination register address for the next stage

    // Sign Extended Immediate Signal
    output logic [31:0] imm_out,      // 32-bit sign-extended immediate

    // Register File Signals
    input  logic CLK,                 
    input  logic RSTn,                
    input  logic we,                  // Write enable for register file (from Write-back Unit)
    input  logic [31:0] write_data,   // Write data (from Write-back Unit)
    input  logic [4:0] write_addr,    // Write address rd (from Write-back Unit)
    output logic [31:0] read_data1,   // Read data port 1 from register file
    output logic [31:0] read_data2,   // Read data port 2 from register file

    // Inputs from ID/EX stage (for hazard detection)
    input  logic [4:0] id_ex_rd,      // Destination register from the ID/EX stage
    input  logic id_ex_reg_write,     // Register write signal from the ID/EX stage

    // Inputs from IF/ID stage (for hazard detection)
    input  logic instr_valid, 

    // Output for hazard detection
    output logic forward_signal,      // Forwarding signal to Execution Unit

    // Control signals
    output logic branch,              // Branch signal (used for checking conditional branches)
    output logic jump,                // Jump signal (used for unconditional jumps)
    output logic jal,                 // Indicates JAL operation (for Execution Unit)
    output logic jalr,                // Indicates JALR operation (for Execution Unit)
    output logic alu_src1,            // ALU source signal (for Execution Unit)
    output logic alu_src2,            // ALU source signal (for Execution Unit)
    output logic [2:0] alu_control,   // ALU control signal (for Execution Unit)
    output logic mem_to_reg,          // Memory to Register Load signal (for Write-back Unit)
    output logic mem_read,            // Memory Read signal (for Memory Unit)
    output logic mem_write,           // Memory Write signal (for Memory Unit)
    output logic reg_write            // Register Write signal (for Write-back Unit)

);

    // Decode fields from the instruction
    logic [4:0] rs1;           // rs1 for register file
    logic [4:0] rs2;           // rs2 for register file
    logic [6:0] opcode;        // Opcode for the control unit
    logic [2:0] funct3;        // Funct3 for control unit and ALU control module
    logic [6:0] funct7;        // Funct7 for control unit and ALU control module
    logic [1:0] alu_op;        // ALU operation signal for ALU control module

    // Instantiate the immediate_generator
    immediate_generator imm_gen(
        .instruction(instruction),
        .imm_out(imm_out)
    );

    // Instantiate the register_file
    register_file reg_file(
        .CLK(CLK),
        .RSTn(RSTn),
        .reg_write(we),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Instantiate the control unit
    control_unit cu(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .branch(branch),
        .jump(jump),
        .jal(jal),
        .jalr(jalr),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_op(alu_op),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write)
    );

    // Instantiate the Hazard Detection Unit
    hdu_unit hdu(
        .CLK(CLK),
        .RSTn(RSTn),
        .id_rs1(rs1),
        .id_rs2(rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_reg_write(id_ex_reg_write),
        .mem_to_reg(mem_to_reg),
        .forward_signal(forward_signal),
        .instr_valid(instr_valid)
    );

    // Instantiate the ALU control module
    alu_control alu_cu(
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );

    // Decode based on opcode
    always_comb begin
        opcode = instruction[6:0];

        case (opcode)
            // For R-type instructions
            OPCODE_RTYPE: begin
                funct7 = instruction[31:25];
                rs2 = instruction[24:20];
                rs1 = instruction[19:15];
                funct3 = instruction[14:12];
                rd = instruction[11:7];
            end
            // For I-type instructions
            OPCODE_ITYPE1, OPCODE_ITYPE2, OPCODE_ITYPE3: begin
                // No funct7, rs2 for I-type
                rs1 = instruction[19:15];
                funct3 = instruction[14:12];
                rd = instruction[11:7];
                funct7 = 7'b0000000;
                rs2 = 5'b00000;
            end
            // For S-type instructions
            OPCODE_STYPE: begin
                // No funct7, rd for S-type
                rs2 = instruction[24:20];
                rs1 = instruction[19:15];
                funct3 = instruction[14:12];
                funct7 = 7'b0000000;
                rd = 5'b00000;
            end
            // For SB-type instructions
            OPCODE_SBTYPE: begin
                // No funct7, rd for SB-type
                rs2 = instruction[24:20];
                rs1 = instruction[19:15];
                funct3 = instruction[14:12];
                funct7 = 7'b0000000;
                rd = 5'b00000;
            end
            // For U-type instructions
            OPCODE_UTYPE1, OPCODE_UTYPE2: begin
                // No funct7, funct3, rs1, rs2 for U-type
                rd = instruction[11:7];
                funct7 = 7'b0000000;
                rs2 = 5'b00000;
                rs1 = 5'b00000;
                funct3 = 3'b000;
            end
            // For UJ-type instructions
            OPCODE_UJTYPE: begin
                // No funct7, funct3, rs1, rs2 for UJ-type
                rd = instruction[11:7];
                funct7 = 7'b0000000;
                rs2 = 5'b00000;
                rs1 = 5'b00000;
                funct3 = 3'b000;
            end

            default: begin
                // Default case to handle unknown opcodes
                funct7 = 7'b0000000;
                rs2 = 5'b00000;
                rs1 = 5'b00000;
                funct3 = 3'b000;
                rd = 5'b00000;
            end
        endcase
    end
endmodule
