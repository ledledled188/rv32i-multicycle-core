module program_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire        PCWrite,
    input  wire [31:0] PCNext,
    output reg  [31:0] PC
);

    always @(posedge clk) begin
        if (reset) begin
            PC <= 32'h0040_0000;
        end
        else if (PCWrite) begin
            PC <= PCNext;
        end
    end

endmodule