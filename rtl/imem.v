module imem #(
    parameter ADDR_WIDTH   = 22,               //4MB
    parameter MEM_INIT_FILE = "firmware.hex"   //$readmemh file, 32-bit words, one per line
)(
    input  wire [ADDR_WIDTH-1:0] Adr,    //byte address from decoder
    output wire [31:0]           RD
);

    localparam WORDS = (1 << ADDR_WIDTH) / 4;

    reg [31:0] mem [0:WORDS-1];

    initial begin
        if (MEM_INIT_FILE != "")
            $readmemh(MEM_INIT_FILE, mem);
    end

    assign RD = mem[Adr[ADDR_WIDTH-1:2]]; //bottom 2 bits are ignored

endmodule
