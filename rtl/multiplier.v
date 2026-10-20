

//  ---------- INLCUDED BLOCK: multiplier  ---------- 
`timescale 1ns / 1ps

module multiplier (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  mul_op,
    output reg [31:0] result
);

    wire signed [63:0] prod_signed;
    wire        [63:0] prod_unsigned;
    wire signed [63:0] prod_su;

    assign prod_signed   = $signed(a) * $signed(b);
    assign prod_unsigned = a * b;
    assign prod_su       = $signed(a) * $signed({1'b0, b});

    always @(*) begin
        case (mul_op)
            4'h0: result = prod_signed[31:0];    // MUL
            4'h1: result = prod_signed[63:32];   // MULH
            4'h2: result = prod_su[63:32];       // MULHSU
            4'h3: result = prod_unsigned[63:32]; // MULHU
            default: result = 32'b0;
        endcase
    end

endmodule