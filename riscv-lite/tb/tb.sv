`timescale 1ns/1ps

module riscv_top_tb;

    // Testbench signals
    logic CLK;
    logic RSTn;
    logic enable;
    logic [31:0] text_base_address_top;
    logic [31:0] read_instr_top;
    logic imem_valid_top;
    logic imem_rdy_top;

    logic imem_proc_req_top;
    logic imem_we_top;
    logic [31:0] imem_addr_out_top; 

    logic [31:0] WDATA_top;     // Not connected (for imem)

    logic [31:0] data_base_address_top;
    logic [31:0] read_data_top;
    logic dmem_valid_top;
    logic dmem_rdy_top;
    logic dmem_proc_req_top;
    logic dmem_we_top;
    logic [31:0] dmem_addr_out_top; 
    logic [31:0] dmem_wdata_top;

    // Variables for file I/O
    integer file_id;
    string filename;
    string line;

    // Instantiate the riscv_top module
    riscv_top dut (
        .CLK(CLK),
        .RSTn(RSTn),
        .enable(enable),
        .text_base_address_top(text_base_address_top),
        .read_instr_top(read_instr_top),
        .imem_valid_top(imem_valid_top),
        .imem_rdy_top(imem_rdy_top),
        .imem_proc_req_top(imem_proc_req_top),
        .imem_we_top(imem_we_top),
        .imem_addr_out_top(imem_addr_out_top),
        .data_base_address_top(data_base_address_top),
        .read_data_top(read_data_top),
        .dmem_valid_top(dmem_valid_top),
        .dmem_rdy_top(dmem_rdy_top),
        .dmem_proc_req_top(dmem_proc_req_top),
        .dmem_we_top(dmem_we_top),
        .dmem_addr_out_top(dmem_addr_out_top),
        .dmem_wdata_top(dmem_wdata_top)
    );

    // Instantiate mem_wrap_fake for IMEM
    mem_wrap_fake #(
        .CONTENT_TYPE(0),
        .tco(1ps),
        .tpd(1ps)
    ) imem (
        .CLK(CLK),
        .RSTn(RSTn),
        .PROC_REQ(imem_proc_req_top),
        .MEM_RDY(imem_rdy_top),
        .ADDR(imem_addr_out_top),
        .WE(imem_we_top),
        .WDATA(WDATA_top), // Not connected to if_unit
        .RDATA(read_instr_top),
        .VALID(imem_valid_top)
    );

    // Instantiate mem_wrap_fake for DMEM
    mem_wrap_fake #(
        .CONTENT_TYPE(1),
        .tco(1ps),
        .tpd(1ps)
    ) dmem (
        .CLK(CLK),
        .RSTn(RSTn),
        .PROC_REQ(dmem_proc_req_top),
        .MEM_RDY(dmem_rdy_top),
        .ADDR(dmem_addr_out_top),
        .WE(dmem_we_top),
        .WDATA(dmem_wdata_top),
        .RDATA(read_data_top),
        .VALID(dmem_valid_top)
    );

    // Clock generation
    always #780ps CLK = ~CLK;

    // Test sequence
    initial begin
        // Initialize signals
        CLK = 0;
        RSTn = 0;
        enable = 0;

        // Read text_base_address from file using file I/O
        filename = "./text_init.hex";
        file_id = $fopen(filename, "r");
        if (file_id == 0) begin
            $display("Failed to open %s", filename);
            $finish;
        end
        if (!$feof(file_id)) begin
            $fgets(line, file_id);
            $sscanf(line, "%h", text_base_address_top);
        end
        $fclose(file_id);

        // Read data_base_address from file using file I/O
        filename = "./data_init.hex";
        file_id = $fopen(filename, "r");
        if (file_id == 0) begin
            $display("Failed to open %s", filename);
            $finish;
        end
        if (!$feof(file_id)) begin
            $fgets(line, file_id);
            $sscanf(line, "%h", data_base_address_top);
        end
        $fclose(file_id);

		@(negedge CLK);
		@(negedge CLK);
        // Apply reset
        RSTn = 1;

        // Enable processor
        enable = 1;
    end

endmodule

