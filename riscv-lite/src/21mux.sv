module mux2to1(
    input  logic       select,    // Select signal
    input  logic [31:0] in0,      // 32-bit input 0
    input  logic [31:0] in1,      // 32-bit input 1
    output logic [31:0] out       // 32-bit output
);

    // Combinational logic to select the output based on the select signal
    always_comb begin
        if(select) begin
            out = in1; // If select is 1, choose input 1
        end
        else begin
            out = in0; // If select is 0, choose input 0
        end
    end

endmodule

