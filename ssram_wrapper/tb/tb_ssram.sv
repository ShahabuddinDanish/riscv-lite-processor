`timescale 1ns/1ps

module riscv_ssram_tb;

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
    integer file, r;
    logic [31:0] instr_data;
    integer file2, r2;
    logic [31:0] data_data;

    // SSRAM initialization signals
    logic init_imem;
    logic [31:0] imem_addr_init;
    logic [31:0] imem_din_normal, imem_din_init;
    logic [31:0] imem_addr_muxed, imem_din_muxed;
    logic imem_web0_init;
    logic imem_web0_muxed;

    logic init_dmem;
    logic [31:0] dmem_addr_normal, dmem_addr_init;
    logic [31:0] dmem_din_normal, dmem_din_init;
    logic [31:0] dmem_addr_muxed, dmem_din_muxed;
    logic dmem_web0_normal, dmem_web0_init;
    logic dmem_web0_muxed;


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

    sram_32_1024_wrapper memories_wrapper(
        .CLK(CLK),
        .RSTn(RSTn),
        .web0_imem(imem_web0_muxed),
        .web0_dmem(dmem_web0_muxed),
        .imem_addr(imem_addr_muxed),
        .dmem_addr(dmem_addr_muxed),
        .din_imem(imem_din_muxed),
        .din_dmem(dmem_din_muxed),
        .dout_imem(read_instr_top),
        .dout_dmem(read_data_top),
        .PROC_REQ_IMEM(imem_proc_req_top),
        .PROC_REQ_DMEM(dmem_proc_req_top),
        .MEM_RDY_IMEM(imem_rdy_top),
        .MEM_RDY_DMEM(dmem_rdy_top),
        .VALID_IMEM(imem_valid_top),
        .VALID_DMEM(dmem_valid_top),
        .init_imem(init_imem),
        .init_dmem(init_dmem)
    );

    always_comb begin
        if (init_imem) begin
            // Initialization phase
            imem_addr_muxed = imem_addr_init;
            imem_din_muxed = imem_din_init;
            imem_web0_muxed = imem_web0_init;
        end else if (!init_imem) begin
            // Normal operation
            imem_addr_muxed = imem_addr_out_top;
            imem_din_muxed = imem_din_normal;
            imem_web0_muxed = imem_we_top;
        end
    end

    always_comb begin
        if (init_dmem) begin
            // Initialization phase
            dmem_addr_muxed = dmem_addr_init;
            dmem_din_muxed = dmem_din_init;
            dmem_web0_muxed = dmem_web0_init;
        end else if (!init_dmem) begin
            // Normal operation
            dmem_addr_muxed = dmem_addr_out_top;
            dmem_din_muxed = dmem_wdata_top;
            dmem_web0_muxed = dmem_we_top;
        end
    end

    // Clock generation
    always #370ps CLK = ~CLK;

        initial begin
        // SSRAM Initialization
        init_dmem = 1;
        file2 = $fopen("data.bin", "r");
        if (file2 == 0) begin
            $display("Error: Could not open data.bin");
            $finish;
        end
        for (int data_addr = 0; !$feof(file2); data_addr=data_addr+4) begin
            r2 = $fscanf(file2, "%h\n", data_data);
            if (r2 > 0) begin
                dmem_din_init = data_data;
                dmem_addr_init = data_addr; // Assuming address needs to be set
                dmem_web0_init = 1; // Activate write enable
                @(posedge CLK); // Duration of write cycle
                dmem_web0_init = 0; // Deactivate write enable
            end
        end
        init_dmem = 0;
        $fclose(file2);
    end

    // Test sequence
    initial begin
        // Initialize signals
        CLK = 0;
        RSTn = 0;
        enable = 0;
        init_imem = 1;

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

        // SSRAM Initialization
        file = $fopen("main.bin", "r");
        if (file == 0) begin
            $display("Error: Could not open main.bin");
            $finish;
        end

        for (int instr_addr = 0; !$feof(file); instr_addr=instr_addr+4) begin
            r = $fscanf(file, "%h\n", instr_data);
            if (r > 0) begin
                imem_din_init = instr_data;
                imem_addr_init = instr_addr; // Assuming address needs to be set
                imem_web0_init = 1; // Activate write enable
                @(posedge CLK); // Duration of write cycle
                imem_web0_init = 0; // Deactivate write enable
            end
        end
        init_imem = 0;
        $fclose(file);

        // Apply reset
		@(negedge CLK);
		@(negedge CLK);
        RSTn = 1;

        // Enable processor
        enable = 1;
    end

endmodule

