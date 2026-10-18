package riscv_constants;

    // Opcode and function encoding for different instruction types

    // I-TYPE
    localparam OPCODE_ITYPE1 = 7'b0010011;
    localparam OPCODE_ITYPE2 = 7'b0000011;
    localparam OPCODE_ITYPE3 = 7'b1100111;

    localparam OPCODE_ADDI   = 7'b0010011;
    localparam OPCODE_LW     = 7'b0000011;
    localparam OPCODE_JALR   = 7'b1100111;

    localparam FUNCT3_ADDI    = 3'b000;
    localparam FUNCT3_LW      = 3'b010;
    localparam FUNCT3_JALR    = 3'b000;

    // R-TYPE
    localparam OPCODE_RTYPE  = 7'b0110011;

    localparam OPCODE_ADD    = 7'b0110011;
    localparam OPCODE_SUB    = 7'b0110011;

    localparam FUNCT3_ADD     = 3'b000;
    localparam FUNCT3_SUB     = 3'b000;

    localparam FUNCT7_ADD     = 7'b0000000;
    localparam FUNCT7_SUB     = 7'b0100000;

    // U-TYPE
    localparam OPCODE_UTYPE1 = 7'b0010111;
    localparam OPCODE_UTYPE2 = 7'b0110111;

    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_LUI    = 7'b0110111;

    // S-TYPE
    localparam OPCODE_STYPE  = 7'b0100011;

    localparam OPCODE_SW     = 7'b0100011;

    localparam FUNCT3_SW      = 3'b010;

    // SB-TYPE
    localparam OPCODE_SBTYPE = 7'b1100011;

    localparam OPCODE_BLTU   = 7'b1100011;
    localparam OPCODE_BGE    = 7'b1100011;

    localparam FUNCT3_BLTU    = 3'b110;
    localparam FUNCT3_BGE     = 3'b101;

    // UJ-TYPE
    localparam OPCODE_UJTYPE = 7'b1101111;

    localparam OPCODE_JAL    = 7'b1101111;

    // ALU operation control values 
    localparam ALU_NOP = 3'b000; // Do nothing
    localparam ALU_ADD = 3'b001; // Add operation
    localparam ALU_SUB = 3'b010; // Subtract operation
    localparam ALU_SLT = 3'b011; // Set less than
    localparam ALU_SGE = 3'b100; // Set greater than or equal operation


endpackage

