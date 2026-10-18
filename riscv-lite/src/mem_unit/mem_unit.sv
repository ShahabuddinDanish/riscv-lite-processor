module memory_unit(
    input  logic CLK,
    input  logic RSTn,
    input  logic [31:0] data_base_address,
    output logic stall,

    // Inputs from Execute Unit
    input  logic [31:0] alu_result,  // Address for memory operations
    input  logic [31:0] operand2,    // Data for store operations

    // Control signals from Decode Unit
    input  logic mem_read, 
    input  logic mem_write,

    // Interface for Req/Ready Protocol
    input  logic [31:0] RDATA,
    input  logic VALID,
    input  logic MEM_RDY,
    output logic PROC_REQ,
    output logic WE,
    output logic [31:0] ADDR,
    output logic [31:0] WDATA,

    // Data output to Write-back Unit
    output logic [31:0] read_data
);

    logic [31:0] rdata_fetched;

    // Request-Response Pairing Counters
    logic [7:0] request_counter;
    logic [7:0] response_counter;
    logic [7:0] real_request_count;
    
    // Internal Flags
    logic valid_fetched;
    logic mem_read_previous;
    logic mem_write_previous;
    logic mem_read_transition;
    logic mem_write_transition;

always_ff @(posedge CLK or negedge RSTn) begin
    if (!RSTn) begin
        request_counter <= 0;
        response_counter <= 0;
    end else begin
        if ((!MEM_RDY && !VALID) && request_counter >= 5'h1F && !(stall)) begin
            // Detect counter overflow and dynamically reset both counters
            // Counters are 8 bit and are set to reset at 5 bits (maximum 1F)
            // This keeps a buffer of 224 requests
            // Some buffer is necessary if memory is RDY & VALID continuously for multiple cycles
            // Ensures dynamic reset only happens when new requests aren't being made and when an issued operation is not underway
            request_counter <= request_counter - response_counter;
            response_counter <= 0;
        end
        if (MEM_RDY) begin
            request_counter <= request_counter + 1;
        end 
        if (VALID) begin
            response_counter <= response_counter + 1;
        end
    end
end

always_ff @(posedge CLK or negedge RSTn) begin
    if (!RSTn) begin
        mem_read_previous <= 1'b0;
        mem_write_previous <= 1'b0;
        mem_read_transition <= 1'b0; 
        mem_write_transition <= 1'b0;
    end else begin
        // Detect transition from 0 to 1
        // Necessary to trigger mem op as otherwise control signals latch on stall and real request count keeps incrementing
        mem_read_transition <= !mem_read_previous && mem_read;
        mem_write_transition <= !mem_write_previous && mem_write;

        // Store the previous state
        mem_read_previous <= mem_read;
        mem_write_previous <= mem_write;
    end
end

always_ff @(posedge CLK or negedge RSTn) begin
    if (!RSTn) begin
        PROC_REQ <= 1; // Fixed at 1 for LSU as it can remain LOW for numerous cycles, memory stalls if PROC_REQ=0 when MEM_RDY=1
        ADDR <= data_base_address;
        WDATA <= 32'b0;
        rdata_fetched <= 32'b0;
        real_request_count <= 8'b0;
        valid_fetched <= 1'b0;
        WE <= 0;
    end else begin
        // Handle write operations
        if (mem_write_transition) begin
            ADDR <= alu_result;
            WE <= mem_write;
            WDATA <= operand2;
            real_request_count <= request_counter;
        end else if (mem_read_transition) begin // Handle read operations
            ADDR <= alu_result;
            WE <= 0;
            WDATA <= 32'b0;
            if (!MEM_RDY) begin
                real_request_count <= request_counter;
            end
            if (MEM_RDY) begin
                real_request_count <= (request_counter + 1);
            end
        end
        if (!stall && !mem_read && !mem_write) begin
            WE <= 0;     // Reset after fulfilling write request to avoid unnecessary writes
            if (!mem_read && !mem_write) begin
                real_request_count <= 8'hFF;     // Reset to max after a request is fulfilled
            end
        end
        if (VALID) begin
            valid_fetched <= 1;
            rdata_fetched <= RDATA;
        end else if (!VALID) begin
            valid_fetched <= 0;
            rdata_fetched <= 32'b0;
        end
    end
end

always_ff @(posedge CLK or negedge RSTn) begin
    if (!RSTn) begin
        read_data = 32'b0;
    end else begin
        if (valid_fetched && (response_counter > real_request_count) && !mem_write) begin
            read_data = rdata_fetched;
        end
    end
end

always_comb begin
    stall = 0;
    if (mem_read || mem_write) begin
        stall = 1;
    end
    if ((response_counter > real_request_count) && !valid_fetched) begin
        // Read data is forwarded in the next cycle after valid read op is complete
        // if stall is released at the same time valid read op is completed, the pipeline
        // moves on and read data is lost. So we wait one cycle to release stall 
        stall = 0;
    end
end

endmodule
