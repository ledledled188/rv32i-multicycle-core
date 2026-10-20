module instruction_register (
    input  wire        clk,
    input  wire        reset,
    input  wire        IRWrite,
    input  wire [31:0] InstrIn,
    output reg  [31:0] Instr
);

    always @(posedge clk) begin
        if (reset) begin
            Instr <= 32'b0;
        end
        else if (IRWrite) begin
            Instr <= InstrIn;
        end
    end

endmodule