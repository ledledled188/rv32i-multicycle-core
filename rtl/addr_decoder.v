module addr_decoder (
    input  wire        clk, // Kept for interface compatibility; not required by current mux
    input  wire [31:0] Adr,
    input  wire        WE,
    input  wire [3:0]  BW,
    input  wire [31:0] WD,

    output wire [12:0] DMEM_Adr,
    output wire        DMEM_WE,
    output wire        DMEM_OE,
    output wire [3:0]  DMEM_BW,
    output wire [31:0] DMEM_WD,

    output wire [21:0] IMEM_Adr,

    input  wire [31:0] DMEM_RD,
    input  wire [31:0] IMEM_RD,
    output reg  [31:0] RD
);

    localparam IMEM_BASE = 32'h0040_0000;
    localparam IMEM_SIZE = 32'h0040_0000;
    localparam DMEM_BASE = 32'h1001_0000;
    localparam DMEM_SIZE = 32'h0000_2000;

    wire SelImem;
    wire SelDmem;

    assign SelImem = (Adr >= IMEM_BASE) &&
                     (Adr < (IMEM_BASE + IMEM_SIZE));
    assign SelDmem = (Adr >= DMEM_BASE) &&
                     (Adr < (DMEM_BASE + DMEM_SIZE));

    assign IMEM_Adr = Adr[21:0];

    assign DMEM_Adr = Adr[12:0];
    assign DMEM_WE  = WE && SelDmem;
    assign DMEM_OE  = SelDmem;
    assign DMEM_BW  = BW;
    assign DMEM_WD  = WD;

    // The controller keeps the DMEM address selected throughout MEM_ACCESS
    // and LOAD_WB. Selecting from the current address lets the following
    // FETCH cycle immediately return to IMEM without a stale DMEM cycle.
    always @(*) begin
        if (SelDmem)
            RD = DMEM_RD;
        else if (SelImem)
            RD = IMEM_RD;
        else
            RD = 32'b0;
    end

endmodule
