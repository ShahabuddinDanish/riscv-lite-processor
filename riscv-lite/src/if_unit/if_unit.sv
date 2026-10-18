module if_unit (
    input  logic CLK,
    input  logic RSTn,
    input  logic [31:0] read_instr,     // Instruction read from memory

    output logic [31:0] instr_out,      // Instruction output to Decode unit
	output logic [31:0] pc_out,         // PC output to Decode unit
    output logic instr_valid,           // Valid instruction flag to Decode unit

    // Interface for Req/Ready Protocol
    input  logic VALID,
    input  logic MEM_RDY,
    output logic PROC_REQ,
    output logic WE,
    output logic [31:0] addr_out,           // Address output to instruction memory

    // Control signals
    input  logic stall,
    input  logic branch_condition,          // Branch signal from execution stage
    input  logic [31:0] branch_address,     // Branch address from execution stage
    input  logic [31:0] text_base_address
);

    logic [31:0] sAddr;
    logic [31:0] sInstr;
    logic [31:0] saved_branch_address;  // Signal to store branch address
    logic [31:0] pc_hold;           // Holds current PC during a stall
    logic [31:0] pc_exec;           // Holds previously executed valid instruction
    logic [31:0] pc_queue [0:15];   // FIFO to handle PC for outstanding requests
    logic sInstr_valid;
    int head, tail;                 // FIFO queue pointers

    // Internal Flags
    logic fifo_full, fifo_empty;    // FIFO full and empty flags
    logic stall_active;             // Flag to indicate an active stall
    logic stall_active_previous;
    logic first_run;                // Flag to indicate startup
    logic waiting_for_branch;       // Flag for unresolved branch  
    logic valid_out;

	always_ff @(posedge CLK or negedge RSTn) begin
		if (!RSTn) begin
		    pc_out <= text_base_address;
            first_run <= 1;
            head <= 0;
		end else begin
            if (first_run && PROC_REQ) begin
                first_run <= 0;
                pc_out <= text_base_address;
            end else if (VALID) begin
                head <= (head + 1) % 16;        // Wrap around
                pc_out <= pc_queue[head];       // Dequeue PC FIFO
                fifo_empty <= (head == tail);   // Check if FIFO is empty after dequeue
            end
		end
	end

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            tail <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            // FIFO enqueue logic
            if (PROC_REQ && MEM_RDY && !fifo_full) begin
                tail <= (tail + 1) % 16; // Wrap around
                pc_queue[tail] <= sAddr; // Store the PC at the time of fetch request
                fifo_empty <= 0; // FIFO not empty anymore
                fifo_full <= ((tail + 1) % 16) == head; // Check if FIFO is full after enqueue
            end
        end
    end

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            sAddr <= text_base_address;
            saved_branch_address <= 32'h0;
            waiting_for_branch <= 0;
        end else begin
            if (stall_active) begin
                sAddr <= pc_hold;
            end else if (!stall) begin
                if (branch_condition) begin
                    waiting_for_branch <= 1;
                    sAddr <= branch_address;
                    saved_branch_address <= branch_address;
                end else if (waiting_for_branch && (pc_queue[head] == saved_branch_address)) begin
                    waiting_for_branch <= 0;
                end else if (PROC_REQ && MEM_RDY) begin
                    if (!branch_condition) begin
                        sAddr <= sAddr + 4;
                        if (instr_valid) begin // Clears the saved branch address after it is fetched
                            saved_branch_address <= 0;
                        end
                    end 
                end
            end
        end
    end

    assign addr_out = sAddr;

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            stall_active_previous <= 0;
        end else begin
            // Store the previous state
            stall_active_previous <= stall;
        end
    end

    always_comb begin
        // Detect transition from 0 to 1
        stall_active = !stall_active_previous && stall;
    end

    always_comb begin
        pc_hold = 32'b0;    // Default value
        if (stall_active && !valid_out) begin
            pc_hold = pc_out + 4;
        end else if (stall_active && valid_out) begin
            pc_hold = pc_out;
        end
    end

	always_ff @(posedge CLK or negedge RSTn) begin
		if (!RSTn) begin
            WE <= 1'b0;
            sInstr <= 1'b0;
            valid_out <= 1'b0;
            sInstr_valid <= 1'b0;
            pc_exec <= 32'b0;
            sInstr <= 32'b0;
        end else begin
            valid_out <= VALID;
            if (valid_out) begin
                if (!stall && instr_valid) begin
                    pc_exec <= pc_out;          // Except stall, pc_out will always be the last valid pc stored 
                end
            end
            if (VALID) begin
                // In case of stalls, we issue NOPs until the instr with correct pc is fetched
                if (stall && (pc_queue[head] != pc_hold)) begin
                    sInstr <= 32'h00000013;     // NOP Instruction
                    sInstr_valid <= 0;
                end else if (stall && (pc_queue[head] == pc_hold)) begin
                    sInstr <= read_instr;
                    sInstr_valid <= 1;
                end else begin
                    // During normal op in case of branches or jumps, NOPs issued until pc popped from FIFO equals branch address
                    if ((waiting_for_branch && (pc_queue[head] != saved_branch_address)) || branch_condition) begin
                        sInstr <= 32'h00000013;     // NOP Instruction
                        sInstr_valid <= 0;
                    // Once pc popped from FIFO equals branch address, and is not the last executed instruction, it is issued
                    // However if the last executed instruction is equal to branch address, it means a branch to itself
                    // In that case the instruction is still issued
                    end else if ((pc_queue[head] == saved_branch_address) && (!(pc_exec == pc_queue[head]) || pc_exec == saved_branch_address)) begin
                        sInstr <= read_instr;
                        sInstr_valid <= 1;
                    // Only if pc popped from FIFO is not equal to last valid pc executed, the instruction is valid
                    // Important logic to not repeat same instruction after stalls 
                    end else if (!waiting_for_branch && !(pc_exec == pc_queue[head])) begin
                        sInstr <= read_instr;
                        sInstr_valid <= 1;
                    // If pc popped from FIFO is equal to last valid pc executed, it means instruction is repeated after stall
                    // Since it's a repeat instruction, a NOP is sent to wait for valid instruction
                    end else if (!waiting_for_branch && (pc_exec == pc_out)) begin
                        sInstr <= 32'h00000013;
                        sInstr_valid <= 0;
                    end
                end
		    end
        end
	end

    // Combinational logic to forward valid instruction once and reset the signal
    // Important so that instructions are not repeated in every cycle till next one is fetched
    always_comb begin
        if (valid_out) begin
            instr_out = sInstr;
            instr_valid = sInstr_valid;
        end else if (!valid_out) begin
            instr_out = 32'h00000013;
            instr_valid = 0;
        end
    end

    // always requesting because memory stalls when MEM_RDY = 1 and PROC_REQ = 0
    assign PROC_REQ = 1;

endmodule
