module reg_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        RegWrite,

    input  wire [4:0]  Rs1,
    input  wire [4:0]  Rs2,
    input  wire [4:0]  Rd,

    input  wire [31:0] WriteData,

    output wire [31:0] RD1,
    output wire [31:0] RD2
);

    // 32 registers of 32-bit width
    reg [31:0] registers [31:0];

    // Asynchronous Read (x0 is hardwired to 0)
    assign RD1 = (Rs1 == 5'b0) ? 32'b0 : registers[Rs1];
    assign RD2 = (Rs2 == 5'b0) ? 32'b0 : registers[Rs2];

    // Synchronous Write
    integer i;
    always @(posedge clk) 
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (RegWrite && (Rd != 5'b0)) begin
            registers[Rd] <= WriteData;
        end

    // Probes for GTKWave waveform inspection (exposes x0 through x7 directly)
    wire [31:0] x0 = 32'b0;
    wire [31:0] x1 = registers[1];
    wire [31:0] x2 = registers[2];
    wire [31:0] x3 = registers[3];
    wire [31:0] x4 = registers[4];
    wire [31:0] x5 = registers[5];
    wire [31:0] x6 = registers[6];
    wire [31:0] x7 = registers[7];

endmodule