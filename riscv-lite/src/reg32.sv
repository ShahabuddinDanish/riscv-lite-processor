module register_32bit(
    input  logic CLK,            
    input  logic RSTn,          
    input  logic enable,         // Load (enable) signal
    input  logic [31:0] in,      // 32-bit input data
    output logic [31:0] out      // 32-bit output data
);

    // Register to hold the 32-bit value
    logic [31:0] value;

    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            value <= 32'd0;     // reset the register
        end
        else if (enable) begin
            value <= in;        // Load the input data into the register
        end
    end

    assign out = value;

endmodule
