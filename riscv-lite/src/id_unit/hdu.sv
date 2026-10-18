module hdu_unit(
    input  logic CLK,
    input  logic RSTn,
    input  logic [4:0] id_rs1,          // Source register 1 from the decode unit (Instruction n)
    input  logic [4:0] id_rs2,          // Source register 2 from the decode unit (Instruction n)
    input  logic [4:0] id_ex_rd,        // Destination register from the ID/EX stage (Instruction n-1)
    input  logic id_ex_reg_write,       // Register write signal from the ID/EX stage (Instruction n-1)
    input  logic mem_to_reg,
    input  logic instr_valid, 
    output logic forward_signal         // Forwarding signal to be used in execute unit
);

    logic instr_valid_prev;
    logic s_id_ex_reg_write;
    logic [4:0] s_id_ex_rd;

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            instr_valid_prev <= 0;
        end else begin
            instr_valid_prev <= instr_valid;    // Previous valid instruction for correct ID/EX destination register
        end
    end

    always_comb begin
        forward_signal = 0;
        if (instr_valid_prev) begin
            s_id_ex_rd = id_ex_rd;
            s_id_ex_reg_write = id_ex_reg_write;
        end
        if (instr_valid) begin
            if (s_id_ex_reg_write && s_id_ex_rd != 5'b0) begin
                if (((id_rs1 == s_id_ex_rd) || (id_rs2 == s_id_ex_rd))) begin
                    if (!mem_to_reg) begin
                        forward_signal = 1; // Set the forward signal to indicate a RAW hazard has been detected
                    end
                end
            end
        end
    end
endmodule

