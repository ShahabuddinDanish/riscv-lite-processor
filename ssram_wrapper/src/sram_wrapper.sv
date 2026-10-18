module sram_32_1024_wrapper(
    input  logic CLK,
    input  logic RSTn,
    input  logic web0_imem,
    input  logic web0_dmem, 
    input  logic [31:0] imem_addr,
    input  logic [31:0] dmem_addr,
    input  logic [31:0] din_imem,
    input  logic [31:0] din_dmem,
    output logic [31:0] dout_imem,
    output logic [31:0] dout_dmem,

    // Signals for OBI Request/Ready Protocol
    input  logic PROC_REQ_IMEM,
    input  logic PROC_REQ_DMEM,
    output logic MEM_RDY_IMEM,
    output logic MEM_RDY_DMEM,
    output logic VALID_IMEM,
    output logic VALID_DMEM,

    // Signals for Initializing Memories
    input  logic init_imem,
    input  logic init_dmem
);

    // Memories initializing signals
    logic csb0_imem_muxed;
    logic csb0_dmem_muxed;
    logic [9:0] s_imem_addr_muxed;
    logic [9:0] s_dmem_addr_muxed;

    // Normal operation signals
    logic csb0_imem;
    logic csb0_dmem;
    logic [9:0] s_imem_addr;
    logic [9:0] s_dmem_addr;
    logic [31:0] s_instr;
    logic [31:0] s_din_dmem;
    logic [31:0] s_dout_dmem;

    // FSM states
    typedef enum logic [1:0] {
        RST = 2'b00,
        WAIT = 2'b01,
        PROCESS = 2'b10,
        VALID = 2'b11
    } state_t;

    // FSM state variables
    state_t state_imem, next_state_imem;
    state_t state_dmem, next_state_dmem;

    // Initializing MUX Implementation
    always_comb begin
        if (init_imem) begin
            csb0_imem_muxed = 1'b0;
            // Each memory block is a word, making it word addressable 
            // Dividing the address to use every memory block 
            s_imem_addr_muxed = imem_addr[9:0] >> 2;      
        end else if (!init_imem) begin
            csb0_imem_muxed = csb0_imem;
            s_imem_addr_muxed = s_imem_addr;
        end
    end

    always_comb begin
        if (init_dmem) begin
            csb0_dmem_muxed = 1'b0;
            s_dmem_addr_muxed = dmem_addr[9:0] >> 2;
        end else if (!init_dmem) begin
            csb0_dmem_muxed = csb0_dmem;
            s_dmem_addr_muxed = s_dmem_addr;
        end
    end

    // SSRAM Macro Instances
    sram_32_1024_freepdk45 sram_imem(
        .clk0(CLK),
        .csb0(csb0_imem_muxed),
        .web0(!web0_imem),
        .addr0(s_imem_addr_muxed),
        .din0(din_imem),
        .dout0(s_instr)
    );
    
    sram_32_1024_freepdk45 sram_dmem(
        .clk0(CLK),
        .csb0(csb0_dmem_muxed),
        .web0(!web0_dmem),
        .addr0(s_dmem_addr_muxed),
        .din0(s_din_dmem),
        .dout0(s_dout_dmem)
    );

    // State transition logic
    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            state_imem <= RST;
            state_dmem <= RST;
        end else begin
            state_imem <= next_state_imem;
            state_dmem <= next_state_dmem;
        end
    end

    // Instruction memory state logic
    always_comb begin
        case (state_imem)
            RST: begin
                MEM_RDY_IMEM = 0;           // Memory not ready
                csb0_imem = 1;
                VALID_IMEM = 0;
                next_state_imem = WAIT;
            end
            WAIT: begin
                MEM_RDY_IMEM = 1;       // Ready for next cycle
                csb0_imem = 0;          // Enable memory
                VALID_IMEM = 0;
                if (PROC_REQ_IMEM) begin 
                    // Initiate memory operation
                    // Assign only the 10 LSBs of the 32-bit address to the SSRAM address
                    // 0x3FF max addressable value, we only need 0x138 for maxx program
                    s_imem_addr = imem_addr[9:0] >> 2;
                    next_state_imem = PROCESS;
                end else begin
                    // Wait for a processor request
                    next_state_imem = WAIT;
                end
            end
            PROCESS: begin
                MEM_RDY_IMEM = 0; // Disable memory while a request is being processed
                csb0_imem = 1;
                VALID_IMEM = 0;
                next_state_imem = VALID;
            end
            VALID: begin
                MEM_RDY_IMEM = 0; // Disable memory while a request is being processed
                csb0_imem = 1;
                dout_imem = s_instr;
                VALID_IMEM = 1;
                next_state_imem = WAIT;
            end
        endcase
    end

    // Data memory state logic
    always_comb begin
        case (state_dmem)
            RST: begin
                s_din_dmem = din_dmem;
                MEM_RDY_DMEM = 0;           // Memory not ready
                csb0_dmem = 1;
                VALID_DMEM = 0;
                next_state_dmem = WAIT;
            end
            WAIT: begin
                MEM_RDY_DMEM = 1;       // Ready for next cycle
                csb0_dmem = 0;          // Enable memory
                VALID_DMEM = 0;
                if (PROC_REQ_DMEM) begin 
                    // Initiate memory operation
                    // Assign only the 10 LSBs of the 32-bit address to the SSRAM address
                    // 0x3FF max addressable value, we only need 0x3F8 for maxx program
                    // Dividing address to further increase addressing space as memory is word addressable 
                    s_dmem_addr = dmem_addr[9:0] >> 2;
                    next_state_dmem = PROCESS;
                end else begin
                    // Wait for a processor request
                    next_state_dmem = WAIT;
                end
            end
            PROCESS: begin
                MEM_RDY_DMEM = 0; // Disable memory while a request is being processed
                csb0_dmem = 1;
                VALID_DMEM = 0;
                next_state_dmem = VALID;
            end
            VALID: begin
                MEM_RDY_DMEM = 0; // Disable memory while a request is being processed
                csb0_dmem = 1;
                s_din_dmem = din_dmem;
                dout_dmem = s_dout_dmem;
                VALID_DMEM = 1;
                next_state_dmem = WAIT;
            end
        endcase
    end

endmodule

