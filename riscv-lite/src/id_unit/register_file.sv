module register_file(
    input  logic        CLK,                // Clock signal
    input  logic        RSTn,               // reset signal
    input  logic        reg_write,          // Register write enable signal from WB Unit
    input  logic [4:0]  read_addr1,         // Read address port 1
    input  logic [4:0]  read_addr2,         // Read address port 2
    input  logic [4:0]  write_addr,         // Write address
    input  logic [31:0] write_data,         // Write data
    output logic [31:0] read_data1,         // Read data port 1
    output logic [31:0] read_data2          // Read data port 2
);

/*  RISCV Register File

    x0: the constant value 0
    x1: return address
    x2: stack pointer
    x3: global pointer
    x4: thread pointer
    x5  x7: temporaries
    x8: frame pointer
    x9: saved register
    x10  x11: function arguments/results
    x12  x17: function arguments
    x18  x27: saved registers
    x28  x31: temporaries                  */

    // Define the register array
    logic [31:0] registers[31:0];           // x0 to x31, 32-bit registers 

    // Asynchronous read for port 1
    always_comb begin
        if (read_addr1 == 0) begin
            read_data1 = 32'b0; // Register x0 is hardwired to 0
        end else if (read_addr1 == write_addr && reg_write) begin
            read_data1 = write_data; // Forwarding the write data if addresses match (resolving RAW hazards within register file)
        end else begin
            read_data1 = registers[read_addr1]; // Normal read
        end
    end

    // Asynchronous read for port 2
    always_comb begin
        if (read_addr2 == 0) begin
            read_data2 = 32'b0; // Register x0 is hardwired to 0
        end else if (read_addr2 == write_addr && reg_write) begin
            read_data2 = write_data; // Forwarding the write data if addresses match (resolving RAW hazards within register file)
        end else begin
            read_data2 = registers[read_addr2]; // Normal read
        end
    end

    // Synchronous write on the rising edge of the clock
    always_ff @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            // RSTn all registers except x0 to 0
            int i;
            for (i = 1; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end
        else begin
            if (reg_write && write_addr != 0) begin // Register x0 cannot be written
                registers[write_addr] <= write_data;
            end
        end
    end

endmodule

