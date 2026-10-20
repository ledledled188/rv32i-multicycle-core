module alu (
    input  wire [31:0] SrcA,
    input  wire [31:0] SrcB,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult
);

    localparam ALU_PASS_B = 4'h0;
    localparam ALU_ADD    = 4'h1;
    localparam ALU_SUB    = 4'h2;
    localparam ALU_AND    = 4'h3;
    localparam ALU_OR     = 4'h4;
    localparam ALU_XOR    = 4'h5;
    localparam ALU_SLL    = 4'h6;
    localparam ALU_SRL    = 4'h7;
    localparam ALU_MRS    = 4'h8;
    localparam ALU_SLT    = 4'h9;
    localparam ALU_SLTU   = 4'hA;

    always @(*) begin
        case (ALUControl)

            // PASS_B
            ALU_PASS_B:
                ALUResult = SrcB;

            // ADD
            ALU_ADD:
                ALUResult = SrcA + SrcB;

            // SUB
            ALU_SUB:
                ALUResult = SrcA - SrcB;

            // AND
            ALU_AND:
                ALUResult = SrcA & SrcB;

            // OR
            ALU_OR:
                ALUResult = SrcA | SrcB;

            // XOR
            ALU_XOR:
                ALUResult = SrcA ^ SrcB;

            // SLL - Shift Left Logical
            ALU_SLL:
                ALUResult = SrcA << SrcB[4:0];

            // SRL - Shift Right Logical
            ALU_SRL:
                ALUResult = SrcA >> SrcB[4:0];

            // MRS - Arithmetic Shift Right
            ALU_MRS:
                ALUResult = $signed(SrcA) >>> SrcB[4:0];

            // SLT - Signed Less Than
            ALU_SLT:
                ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'b1 : 32'b0;

            // SLTU - Unsigned Less Than
            ALU_SLTU:
                ALUResult = (SrcA < SrcB) ? 32'b1 : 32'b0;

            default:
                ALUResult = 32'b0;

        endcase
    end

endmodule