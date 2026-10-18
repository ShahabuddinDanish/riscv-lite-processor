module write_back_unit(
        
    // Inputs from Memory Unit
    input logic [31:0] mem_read_data,    // Data read from memory
    input logic mem_to_reg,              // Control signal to select between ALU result and memory read data

    // Inputs from Execution Unit
    input logic [31:0] alu_result,       // Result from ALU
    input logic [31:0] return_address,   // Return address from Execution Unit

    // Inputs from Decode Unit
    input logic [4:0] write_addr,        // Register to write to
    input logic reg_write,               // Control signal to enable writing to register file
    input logic jal,                     // JAL signal from Decode Unit
    input logic jalr,                    // JALR signal from Decode Unit

    // Outputs to Register File
    output logic [31:0] write_data,      // Data to be written to register file
    output logic [4:0] write_reg,        // Address of register to write to
    output logic write_enable            // Enable signal for writing to register
);

    // Instantiate MUX modules
    logic [31:0] mux1_output, mux2_output;

    mux2to1 mux1 (
        .select(jal || jalr),
        .in0(alu_result),
        .in1(return_address),
        .out(mux1_output)
    );

    mux2to1 mux2 (
        .select(mem_to_reg),
        .in0(mux1_output),
        .in1(mem_read_data),
        .out(mux2_output)
    );

    // Combinational logic for selecting data to write to the register file
    always_comb begin

        write_reg = write_addr;
        write_enable = reg_write;
        write_data = mux2_output;

    end

endmodule
