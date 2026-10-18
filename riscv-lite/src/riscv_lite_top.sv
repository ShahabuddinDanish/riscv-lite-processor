module riscv_top(
    input  logic CLK,                   
    input  logic RSTn,                 
    input  logic enable,                
    
    input  logic [31:0] text_base_address_top,
    input  logic [31:0] read_instr_top,
    input  logic imem_valid_top,
    input  logic imem_rdy_top,

    input  logic [31:0] data_base_address_top,
    input  logic [31:0] read_data_top,
    input  logic dmem_valid_top,
    input  logic dmem_rdy_top,

    output logic imem_proc_req_top,
    output logic imem_we_top,
    output logic [31:0] imem_addr_out_top,

    output logic dmem_proc_req_top,
    output logic dmem_we_top,
    output logic [31:0] dmem_addr_out_top, 
    output logic [31:0] dmem_wdata_top
);

    // Signals for connecting IF unit and instruction memory
    logic [31:0] text_base_address_if;
    logic [31:0] read_instr_if;
    logic VALID_if;
    logic MEM_RDY_if;
    logic PROC_REQ_imem;
    logic WE_imem;
    logic [31:0] addr_out_imem;

    // Signals for connecting IF unit and IF/ID stage
    logic [31:0] pc_if_id;                  // EX unit program counter from IF unit to IF/ID stage
    logic [31:0] instruction_if_id;         // Instruction from IF unit to IF/ID stage
    logic instr_valid_if_id;                // Instruction valid flag from IF unit to IF/ID stage

    // Signals for connecting IF/ID stage and ID unit
    logic [31:0] pc_id;                     // Ex unit program counter from IF/ID stage to ID unit
    logic [31:0] instruction_id;            // Instruction from IF/ID stage to ID unit
    logic instr_valid_id;                   // Instruction valid flag from IF/ID stage to ID unit

    // Signals for connecting ID unit and ID/EX stage
    logic [4:0] rd_id_ex;                   // Destination register to MEM/WB stage from ID unit to ID/EX stage
    logic [31:0] imm_out_id_ex;             // Immediate output from ID unit to ID/EX stage
    logic [31:0] read_data1_id_ex;          // Read data 1 from ID unit to ID/EX stage
    logic [31:0] read_data2_id_ex;          // Read data 2 from ID unit to ID/EX stage
    logic branch_id_ex, jump_id_ex;         // Control signals from ID unit to ID/EX stage
    logic jal_id_ex, jalr_id_ex;            // Control signals from ID unit to ID/EX stage
    logic alu_src1_id_ex, alu_src2_id_ex;   // ALU source signals from ID unit to ID/EX stage
    logic [2:0] alu_control_id_ex;          // ALU control signal from ID unit to ID/EX stage
    logic mem_to_reg_id_ex;                 // WB MUX2 select signal from ID unit to ID/EX stage
    logic mem_read_id_ex, mem_write_id_ex;  // MEM unit control signals from ID unit to ID/EX stage
    logic reg_write_id_ex;                  // MEM/WB stage register write control signal from ID unit to ID/EX stage
    logic forward_signal_id_ex;             // EX unit forward signal from ID unit to ID/EX stage

    // Signals for connecting ID/EX stage and EX unit
    logic [31:0] operand1_ex;               // Operand 1 from ID/EX stage to EX unit
    logic [31:0] operand2_ex;               // Operand 2 from ID/EX stage to EX unit
    logic [31:0] imm_ex;                    // Immediate output from ID/EX stage to EX unit
    logic [2:0] alu_control_ex;             // ALU control signal from ID/EX stage to EX unit
    logic alu_src1_ex, alu_src2_ex;         // ALU source signals from ID/EX stage to EX unit
    logic branch_ex, jump_ex;               // Control signals from ID/EX stage to EX unit
    logic jal_ex, jalr_ex;                  // Control signals from ID/EX stage to EX unit
    logic [31:0] pc_ex;                     // IF unit program counter from ID/EX stage to EX unit
    logic mem_to_reg_ex;                    // WB MUX2 select signal from ID/EX stage to EX unit
    logic mem_read_ex, mem_write_ex;        // MEM unit control signals from ID/EX stage to EX unit
    logic reg_write_ex;                     // MEM/WB stage register write control signal from ID/EX stage to EX unit
    logic [4:0] rd_ex;                      // ID unit destination register from ID/EX stage to EX unit
    logic forward_signal_ex;                // EX unit forward signal from ID/EX stage to EX unit
    logic instr_valid_ex;

    // Signals for connecting EX unit and EX/MEM stage
    logic [31:0] alu_result_ex_mem;         // ALU Result from EX unit to EX/MEM stage
    logic [31:0] new_pc_ex_mem;             // IF unit new branch/jump program counter from EX unit to EX/MEM stage
    logic branch_jump_taken_ex_mem;         // IF unit Branch/jump taken control signal from EX unit to EX/MEM stage
    logic [31:0] return_address_ex_mem;     // WB unit return address from EX unit to EX/MEM stage
    
    // Signals for connecting EX/MEM stage and MEM unit
    logic [31:0] alu_result_mem;            // MEM unit and WB unit ALU result from EX/MEM stage to MEM unit
    logic [31:0] operand2_mem;              // Mem unit operand 2 from EX/MEM stage to MEM unit
    logic mem_read_mem, mem_write_mem;      // MEM unit read/write control signals from EX/MEM stage to MEM unit
    logic [31:0] return_address_mem;        // WB unit return address from EX/MEM stage to MEM unit
    logic jal_mem, jalr_mem;                // WB JAL, JALR control signals from EX/MEM stage to MEM unit
    logic [4:0] write_addr_mem;             // WB destination register from EX/MEM stage to MEM unit
    logic reg_write_mem;                    // WB register write control signal from EX/MEM stage to MEM unit
    logic mem_to_reg_mem;                   // WB MUX2 select signal from EX/MEM stage to MEM unit

    // Signals for connecting MEM unit and MEM/WB stage
    logic [31:0] read_data_mem_wb;          // WB unit memory read data from MEM unit to MEM/WB stage

    // Signals for connecting MEM unit and data memory
    logic [31:0] data_base_address_mem;
    logic [31:0] read_data_mem;
    logic VALID_mem;
    logic MEM_RDY_mem;
    logic PROC_REQ_dmem;
    logic WE_dmem;
    logic [31:0] addr_out_dmem;
    logic [31:0] wdata_dmem;
    logic mem_stall;                       // Stall signal from LSU

    // Signals for connecting MEM/WB stage and WB unit
    logic [31:0] mem_read_data_wb;          // WB memory read data from MEM/WB stage
    logic mem_to_reg_wb, jal_wb, jalr_wb;   // WB control signals from MEM/WB stage
    logic [31:0] alu_result_wb;             // WB ALU result from MEM/WB stage
    logic [31:0] return_address_wb;         // WB return address from MEM/WB stage
    logic [4:0] write_addr_wb;              // WB destination register from MEM/WB stage
    logic reg_write_wb;                     // WB register write control signal from MEM/WB stage

    // Signals from EX/MEM stage to IF unit
    logic [31:0] pc_new_if;                 // IF unit new program counter from EX/MEM stage to IF unit
    logic branch_jump_taken_if;             // IF unit branch/jump taken control signal from EX/MEM stage to IF unit

    // Signals from MEM/WB stage to ID unit
    logic write_enable_id;                    // Register write control signal from MEM/WB stage to ID unit

    // Signals from WB unit to ID unit
    logic [4:0] write_addr_id;             // Destination register from WB unit to ID unit 
    logic [31:0] write_data_id;            // Write data from WB unit to ID unit

    assign text_base_address_if = text_base_address_top;
    assign read_instr_if = read_instr_top;
    assign VALID_if = imem_valid_top;
    assign MEM_RDY_if = imem_rdy_top;
    assign imem_proc_req_top = PROC_REQ_imem;
    assign imem_we_top = WE_imem;
    assign imem_addr_out_top = addr_out_imem;

    assign data_base_address_mem = data_base_address_top;
    assign read_data_mem = read_data_top;
    assign VALID_mem = dmem_valid_top;
    assign MEM_RDY_mem = dmem_rdy_top;
    assign dmem_proc_req_top = PROC_REQ_dmem;
    assign dmem_we_top = WE_dmem;
    assign dmem_addr_out_top = addr_out_dmem;
    assign dmem_wdata_top = wdata_dmem;

    // Instantiate Instruction Fetch unit
    if_unit if_unit (
        .CLK(CLK),
        .RSTn(RSTn),
        .branch_condition(branch_jump_taken_if),
        .branch_address(pc_new_if),
        .text_base_address(text_base_address_if),
        .read_instr(read_instr_if),
        .instr_out(instruction_if_id),
        .pc_out(pc_if_id),
        .instr_valid(instr_valid_if_id),
        .VALID(VALID_if),
        .MEM_RDY(MEM_RDY_if),
        .PROC_REQ(PROC_REQ_imem),
        .WE(WE_imem),
        .stall(mem_stall),
        .addr_out(addr_out_imem)
    );

    // Instantiate IF/ID pipeline stage
    if_id_pipeline_stage if_id_stage (
        .CLK(CLK),
        .RSTn(RSTn & !branch_jump_taken_if),
        .enable(enable && !mem_stall),
        .pc_in(pc_if_id),
        .instruction_in(instruction_if_id),
        .instr_valid_if(instr_valid_if_id),
        .pc_out(pc_id),
        .instruction_out(instruction_id),
        .instr_valid_id(instr_valid_id)
    );

    // Instantiate Instruction Decode unit
    decode_unit id_unit (
        .instruction(instruction_id),
        .rd(rd_id_ex),
        .imm_out(imm_out_id_ex),
        .CLK(CLK),
        .RSTn(RSTn),
        .we(write_enable_id),
        .write_data(write_data_id),
        .write_addr(write_addr_id),
        .read_data1(read_data1_id_ex),
        .read_data2(read_data2_id_ex),
        .id_ex_rd(rd_ex),
        .id_ex_reg_write(reg_write_ex),
        .instr_valid(instr_valid_id),
        .forward_signal(forward_signal_id_ex),
        .branch(branch_id_ex),
        .jump(jump_id_ex),
        .jal(jal_id_ex),
        .jalr(jalr_id_ex),
        .alu_src1(alu_src1_id_ex),
        .alu_src2(alu_src2_id_ex),
        .alu_control(alu_control_id_ex),
        .mem_to_reg(mem_to_reg_id_ex),
        .mem_read(mem_read_id_ex),
        .mem_write(mem_write_id_ex),
        .reg_write(reg_write_id_ex)
    );

    // Instantiate ID/EX pipeline stage
    id_ex_pipeline_stage id_ex_stage (
        .CLK(CLK),
        .RSTn(RSTn & !branch_jump_taken_if),
        .enable(enable && !mem_stall),
        .pc(pc_id),
        .read_data1(read_data1_id_ex),
        .read_data2(read_data2_id_ex),
        .imm(imm_out_id_ex),
        .alu_control(alu_control_id_ex),
        .alu_src1(alu_src1_id_ex),
        .alu_src2(alu_src2_id_ex),
        .branch(branch_id_ex),
        .jump(jump_id_ex),
        .jal(jal_id_ex),
        .jalr(jalr_id_ex),
        .mem_to_reg(mem_to_reg_id_ex),
        .mem_read(mem_read_id_ex),
        .mem_write(mem_write_id_ex),
        .reg_write(reg_write_id_ex),
        .rd(rd_id_ex),
        .forward_signal(forward_signal_id_ex),
        .instr_valid(instr_valid_id),
        .operand1(operand1_ex),
        .operand2(operand2_ex),
        .ex_imm(imm_ex),
        .ex_alu_control(alu_control_ex),
        .ex_alu_src1(alu_src1_ex),
        .ex_alu_src2(alu_src2_ex),
        .ex_branch(branch_ex),
        .ex_jump(jump_ex),
        .ex_jal(jal_ex),
        .ex_jalr(jalr_ex),
        .ex_pc(pc_ex),
        .ex_forward_signal(forward_signal_ex),
        .ex_instr_valid(instr_valid_ex),
        .ex_mem_to_reg(mem_to_reg_ex),
        .ex_mem_read(mem_read_ex),
        .ex_mem_write(mem_write_ex),
        .ex_reg_write(reg_write_ex),
        .ex_rd(rd_ex)
    );

    // Instantiate Execute unit
    execution_unit ex_unit (
        .CLK(CLK),
        .RSTn(RSTn),
        .operand1(operand1_ex),
        .operand2(operand2_ex),
        .imm(imm_ex),
        .alu_control(alu_control_ex),
        .alu_src1(alu_src1_ex),
        .alu_src2(alu_src2_ex),
        .branch(branch_ex),
        .jump(jump_ex),
        .jal(jal_ex),
        .jalr(jalr_ex),
        .pc(pc_ex),
        .instr_valid(instr_valid_ex),
        .alu_result_ex_mem(alu_result_mem),
        .forward_signal(forward_signal_ex),
        .alu_result(alu_result_ex_mem),
        .new_pc(new_pc_ex_mem),
        .branch_jump_taken(branch_jump_taken_ex_mem),
        .return_address(return_address_ex_mem)
    );

    // Instantiate EX/MEM pipeline stage
    ex_mem_pipeline_stage ex_mem_stage (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable && !mem_stall),
        .branch_jump_taken_ex(branch_jump_taken_ex_mem),
        .pc_ex(new_pc_ex_mem),
        .alu_result_ex(alu_result_ex_mem),
        .operand2_ex(operand2_ex),
        .return_address_ex(return_address_ex_mem),
        .mem_read_ex(mem_read_ex),
        .mem_write_ex(mem_write_ex),
        .jal_ex(jal_ex),
        .jalr_ex(jalr_ex),
        .write_addr_ex(rd_ex),
        .reg_write_ex(reg_write_ex),
        .mem_to_reg_ex(mem_to_reg_ex),
        .pc_mem(pc_new_if),
        .branch_jump_taken_mem(branch_jump_taken_if),
        .alu_result_mem(alu_result_mem),
        .operand2_mem(operand2_mem),
        .mem_read_mem(mem_read_mem),
        .mem_write_mem(mem_write_mem),
        .return_address_mem(return_address_mem),
        .jal_mem(jal_mem),
        .jalr_mem(jalr_mem),
        .write_addr_mem(write_addr_mem),
        .reg_write_mem(reg_write_mem),
        .mem_to_reg_mem(mem_to_reg_mem)
    );

    // Instantiate Memory Unit
    memory_unit mem_unit (
        .CLK(CLK),
        .RSTn(RSTn),
        .data_base_address(data_base_address_mem),
        .stall(mem_stall),
        .alu_result(alu_result_mem),
        .operand2(operand2_mem),
        .mem_read(mem_read_mem),
        .mem_write(mem_write_mem),
        .RDATA(read_data_mem),
        .VALID(VALID_mem),
        .MEM_RDY(MEM_RDY_mem),
        .PROC_REQ(PROC_REQ_dmem),
        .WE(WE_dmem),
        .ADDR(addr_out_dmem),
        .WDATA(wdata_dmem),
        .read_data(read_data_mem_wb)
    );

    // Instantiate MEM/WB pipeline stage
    mem_wb_pipeline_stage mem_wb_stage (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable && !mem_stall),
        .mem_mem_read_data(read_data_mem_wb),
        .mem_mem_to_reg(mem_to_reg_mem),
        .mem_alu_result(alu_result_mem),
        .mem_return_address(return_address_mem),
        .mem_write_addr(write_addr_mem),
        .mem_reg_write(reg_write_mem),
        .mem_jal(jal_mem),
        .mem_jalr(jalr_mem),
        .wb_mem_read_data(mem_read_data_wb),
        .wb_mem_to_reg(mem_to_reg_wb),
        .wb_alu_result(alu_result_wb),
        .wb_return_address(return_address_wb),
        .wb_write_addr(write_addr_wb),
        .wb_reg_write(reg_write_wb),
        .wb_jal(jal_wb),
        .wb_jalr(jalr_wb)
    );

    // Instantiate WB unit
    write_back_unit wb_unit (
        .mem_read_data(mem_read_data_wb),
        .mem_to_reg(mem_to_reg_wb),
        .alu_result(alu_result_wb),
        .return_address(return_address_wb),
        .write_addr(write_addr_wb),
        .reg_write(reg_write_wb),
        .jal(jal_wb),
        .jalr(jalr_wb),
        .write_data(write_data_id),
        .write_reg(write_addr_id),
        .write_enable(write_enable_id)
    );

endmodule

