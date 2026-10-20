module dmem #(
    parameter ADDR_WIDTH = 13   // 2^13 = 8kB
)(
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0] Adr,   // bottom 2 bits ignored
    input  wire                  WE,    // write enable
    input  wire                  OE,    // read enable
    input  wire [3:0]            BW,    // per-byte write mask
    input  wire [31:0]           WD,    // write data
    output reg  [31:0]           RD     // read data (valid 1 cycle after OE)
);

    localparam WORDS = (1 << ADDR_WIDTH) / 4;
    wire [$clog2(WORDS)-1:0] WordAdr = Adr[ADDR_WIDTH-1:2];

    reg [7:0] mem0 [0:WORDS-1];
    reg [7:0] mem1 [0:WORDS-1];
    reg [7:0] mem2 [0:WORDS-1];
    reg [7:0] mem3 [0:WORDS-1];

    always @(posedge clk) begin
        if (WE) begin
            if (BW[0]) mem0[WordAdr] <= WD[7:0];
            if (BW[1]) mem1[WordAdr] <= WD[15:8];
            if (BW[2]) mem2[WordAdr] <= WD[23:16];
            if (BW[3]) mem3[WordAdr] <= WD[31:24];
        end
        if (OE) begin
            RD <= {mem3[WordAdr], mem2[WordAdr], mem1[WordAdr], mem0[WordAdr]};
        end
    end

endmodule
