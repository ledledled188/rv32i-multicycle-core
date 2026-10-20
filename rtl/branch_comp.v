module branch_comp (
    input  wire [31:0] RD1,
    input  wire [31:0] RD2,
    input  wire        BrUn,     // 1: Unsigned comparison, 0: Signed comparison
    output reg         BrEq,     // 1 if rs1 == rs2
    output reg         BrLT     // 1 if rs1 < rs2
);

    always @(*) begin
        // Equality check (same for signed/unsigned)
        BrEq = (RD1 == RD2);

        // Less Than check
        if (BrUn) begin
            // Unsigned comparison
            BrLT= (RD1 < RD2);
        end else begin
            // Signed comparison
            BrLT= ($signed(RD1) < $signed(RD2));
        end
    end

endmodule