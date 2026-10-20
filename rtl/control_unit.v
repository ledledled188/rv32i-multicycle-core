module control_unit (
    input  wire        clk,
    input  wire        reset,

    input  wire [6:0]  op,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire [11:0] funct12,

    input  wire        BrEq,
    input  wire        BrLT,

    output reg         PCWrite,
    output reg         IRWrite,
    output reg         RegWrite,
    output reg         ALUSrcA,
    output reg         ALUSrcB,
    output reg  [3:0]  ALUControl,
    output reg  [3:0]  MulControl,
    output reg  [3:0]  CRCControl,
    output reg  [2:0]  ImmSrc,

    output reg         BrUn,
    output reg  [1:0]  PCSrc,

    output reg         AdrSrc,
    output reg         MemWrite,
    output reg  [2:0]  ResultSrc,

    output reg  [2:0]  state
);

    localparam FETCH      = 3'b000;
    localparam DECODE     = 3'b001;
    localparam EXECUTE    = 3'b010;
    localparam WRITE_BACK = 3'b011;
    localparam BRANCH     = 3'b100;
    localparam MEM_ADDR   = 3'b101;
    localparam MEM_ACCESS = 3'b110;
    localparam LOAD_WB    = 3'b111;

    localparam ALU_PASS_B = 4'h0;
    localparam ALU_ADD    = 4'h1;
    localparam ALU_SUB    = 4'h2;
    localparam ALU_AND    = 4'h3;
    localparam ALU_OR     = 4'h4;
    localparam ALU_XOR    = 4'h5;
    localparam ALU_SLL    = 4'h6;
    localparam ALU_SRL    = 4'h7;
    localparam ALU_SRA    = 4'h8;
    localparam ALU_SLT    = 4'h9;
    localparam ALU_SLTU   = 4'hA;

    localparam RESULT_ALU = 3'b000;
    localparam RESULT_MEM = 3'b001;
    localparam RESULT_MUL = 3'b010;
    localparam RESULT_CRC = 3'b011;
    localparam RESULT_PC4 = 3'b100;

    localparam PC_SEQ      = 2'b00;
    localparam PC_RELATIVE = 2'b01;
    localparam PC_JALR     = 2'b10;

    localparam OP_LOAD   = 7'b0000011;
    localparam OP_FENCE  = 7'b0001111;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_REG    = 7'b0110011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_SYSTEM = 7'b1110011;

    reg [2:0] next_state;
    reg [3:0] decoded_alu_control;
    reg       valid_alu_instruction;
    reg       valid_branch_instruction;
    reg       branch_taken;

    wire is_reg_instruction;
    wire is_imm_instruction;
    wire is_branch_instruction;
    wire is_load_instruction;
    wire is_store_instruction;
    wire is_mul_instruction;
    wire is_crc_instruction;
    wire is_lui_instruction;
    wire is_auipc_instruction;
    wire is_jal_instruction;
    wire is_jalr_instruction;
    wire is_jump_instruction;
    wire is_fence_instruction;
    wire is_ecall_instruction;
    wire is_ebreak_instruction;
    wire is_system_nop_instruction;
    wire is_execute_instruction;

    assign is_reg_instruction    = (op == OP_REG);
    assign is_imm_instruction    = (op == OP_IMM);
    assign is_branch_instruction = (op == OP_BRANCH);

    assign is_load_instruction = (op == OP_LOAD) &&
                                 ((funct3 == 3'b000) ||
                                  (funct3 == 3'b001) ||
                                  (funct3 == 3'b010) ||
                                  (funct3 == 3'b100) ||
                                  (funct3 == 3'b101));

    assign is_store_instruction = (op == OP_STORE) &&
                                  ((funct3 == 3'b000) ||
                                   (funct3 == 3'b001) ||
                                   (funct3 == 3'b010));

    // Zmmul and Xicrc share the R-type opcode and are separated by funct7.
    assign is_mul_instruction = (op == OP_REG) &&
                                (funct7 == 7'b0000001) &&
                                (funct3 <= 3'b011);

    assign is_crc_instruction = (op == OP_REG) &&
                                (funct7 == 7'b1000000) &&
                                (funct3 <= 3'b010);

    assign is_lui_instruction   = (op == OP_LUI);
    assign is_auipc_instruction = (op == OP_AUIPC);
    assign is_jal_instruction   = (op == OP_JAL);
    assign is_jalr_instruction  = (op == OP_JALR) && (funct3 == 3'b000);
    assign is_jump_instruction  = is_jal_instruction || is_jalr_instruction;

    // This core has no caches, outstanding transactions, or trap/CSR block.
    // Therefore FENCE, ECALL, and EBREAK retire as recognized no-ops.
    assign is_fence_instruction = (op == OP_FENCE) && (funct3 == 3'b000);
    assign is_ecall_instruction = (op == OP_SYSTEM) &&
                                  (funct3 == 3'b000) &&
                                  (funct12 == 12'h000);
    assign is_ebreak_instruction = (op == OP_SYSTEM) &&
                                   (funct3 == 3'b000) &&
                                   (funct12 == 12'h001);
    assign is_system_nop_instruction = is_fence_instruction ||
                                       is_ecall_instruction ||
                                       is_ebreak_instruction;

    assign is_execute_instruction = valid_alu_instruction ||
                                    is_mul_instruction ||
                                    is_crc_instruction ||
                                    is_lui_instruction ||
                                    is_auipc_instruction;

    // Base RV32I register/immediate ALU decoder.
    always @(*) begin
        decoded_alu_control   = ALU_ADD;
        valid_alu_instruction = 1'b0;

        if (is_reg_instruction && !is_mul_instruction && !is_crc_instruction) begin
            case (funct3)
                3'b000: begin
                    if (funct7 == 7'b0000000) begin
                        decoded_alu_control = ALU_ADD;
                        valid_alu_instruction = 1'b1;
                    end
                    else if (funct7 == 7'b0100000) begin
                        decoded_alu_control = ALU_SUB;
                        valid_alu_instruction = 1'b1;
                    end
                end
                3'b001: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_SLL;
                    valid_alu_instruction = 1'b1;
                end
                3'b010: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_SLT;
                    valid_alu_instruction = 1'b1;
                end
                3'b011: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_SLTU;
                    valid_alu_instruction = 1'b1;
                end
                3'b100: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_XOR;
                    valid_alu_instruction = 1'b1;
                end
                3'b101: begin
                    if (funct7 == 7'b0000000) begin
                        decoded_alu_control = ALU_SRL;
                        valid_alu_instruction = 1'b1;
                    end
                    else if (funct7 == 7'b0100000) begin
                        decoded_alu_control = ALU_SRA;
                        valid_alu_instruction = 1'b1;
                    end
                end
                3'b110: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_OR;
                    valid_alu_instruction = 1'b1;
                end
                3'b111: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_AND;
                    valid_alu_instruction = 1'b1;
                end
                default: begin
                    decoded_alu_control = ALU_ADD;
                    valid_alu_instruction = 1'b0;
                end
            endcase
        end
        else if (is_imm_instruction) begin
            case (funct3)
                3'b000: begin
                    decoded_alu_control = ALU_ADD;
                    valid_alu_instruction = 1'b1;
                end
                3'b001: if (funct7 == 7'b0000000) begin
                    decoded_alu_control = ALU_SLL;
                    valid_alu_instruction = 1'b1;
                end
                3'b010: begin
                    decoded_alu_control = ALU_SLT;
                    valid_alu_instruction = 1'b1;
                end
                3'b011: begin
                    decoded_alu_control = ALU_SLTU;
                    valid_alu_instruction = 1'b1;
                end
                3'b100: begin
                    decoded_alu_control = ALU_XOR;
                    valid_alu_instruction = 1'b1;
                end
                3'b101: begin
                    if (funct7 == 7'b0000000) begin
                        decoded_alu_control = ALU_SRL;
                        valid_alu_instruction = 1'b1;
                    end
                    else if (funct7 == 7'b0100000) begin
                        decoded_alu_control = ALU_SRA;
                        valid_alu_instruction = 1'b1;
                    end
                end
                3'b110: begin
                    decoded_alu_control = ALU_OR;
                    valid_alu_instruction = 1'b1;
                end
                3'b111: begin
                    decoded_alu_control = ALU_AND;
                    valid_alu_instruction = 1'b1;
                end
                default: begin
                    decoded_alu_control = ALU_ADD;
                    valid_alu_instruction = 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        valid_branch_instruction = 1'b1;
        branch_taken = 1'b0;

        case (funct3)
            3'b000: branch_taken = BrEq;   // BEQ
            3'b001: branch_taken = ~BrEq;  // BNE
            3'b100: branch_taken = BrLT;   // BLT
            3'b101: branch_taken = ~BrLT;  // BGE
            3'b110: branch_taken = BrLT;   // BLTU
            3'b111: branch_taken = ~BrLT;  // BGEU
            default: begin
                valid_branch_instruction = 1'b0;
                branch_taken = 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            FETCH: next_state = DECODE;

            DECODE: begin
                if (is_branch_instruction || is_jump_instruction)
                    next_state = BRANCH;
                else if (is_load_instruction || is_store_instruction)
                    next_state = MEM_ADDR;
                else if (is_execute_instruction)
                    next_state = EXECUTE;
                else if (is_system_nop_instruction)
                    next_state = FETCH;
                else
                    next_state = FETCH;
            end

            EXECUTE:    next_state = WRITE_BACK;
            WRITE_BACK: next_state = FETCH;
            BRANCH:     next_state = is_jump_instruction ? WRITE_BACK : FETCH;

            MEM_ADDR: next_state = (is_load_instruction || is_store_instruction) ?
                                   MEM_ACCESS : FETCH;

            MEM_ACCESS: next_state = is_load_instruction ? LOAD_WB : FETCH;
            LOAD_WB:    next_state = FETCH;
            default:    next_state = FETCH;
        endcase
    end

    always @(*) begin
        PCWrite    = 1'b0;
        IRWrite    = 1'b0;
        RegWrite   = 1'b0;
        ALUSrcA    = 1'b0;
        ALUSrcB    = 1'b0;
        ALUControl = ALU_ADD;
        MulControl = 4'h0;
        CRCControl = 4'h0;
        ImmSrc     = 3'b000;
        BrUn       = 1'b0;
        PCSrc      = PC_SEQ;
        AdrSrc     = 1'b0;
        MemWrite   = 1'b0;
        ResultSrc  = RESULT_ALU;

        case (state)
            FETCH: begin
                PCWrite = 1'b1;
                IRWrite = 1'b1;
                PCSrc   = PC_SEQ;
            end

            EXECUTE: begin
                if (valid_alu_instruction) begin
                    ALUSrcB    = is_imm_instruction;
                    ALUControl = decoded_alu_control;
                end
                else if (is_mul_instruction) begin
                    MulControl = {1'b0, funct3};
                end
                else if (is_crc_instruction) begin
                    CRCControl = {1'b0, funct3};
                end
                else if (is_lui_instruction) begin
                    ALUSrcB    = 1'b1;
                    ALUControl = ALU_PASS_B;
                    ImmSrc     = 3'b011;
                end
                else if (is_auipc_instruction) begin
                    ALUSrcA    = 1'b1;
                    ALUSrcB    = 1'b1;
                    ALUControl = ALU_ADD;
                    ImmSrc     = 3'b011;
                end
            end

            WRITE_BACK: begin
                if (valid_alu_instruction || is_lui_instruction || is_auipc_instruction) begin
                    RegWrite  = 1'b1;
                    ResultSrc = RESULT_ALU;
                end
                else if (is_mul_instruction) begin
                    RegWrite  = 1'b1;
                    ResultSrc = RESULT_MUL;
                    MulControl = {1'b0, funct3};
                end
                else if (is_crc_instruction) begin
                    RegWrite  = 1'b1;
                    ResultSrc = RESULT_CRC;
                    CRCControl = {1'b0, funct3};
                end
                else if (is_jump_instruction) begin
                    RegWrite  = 1'b1;
                    ResultSrc = RESULT_PC4;
                end
            end

            BRANCH: begin
                if (is_branch_instruction) begin
                    ImmSrc = 3'b010;
                    BrUn   = (funct3 == 3'b110) || (funct3 == 3'b111);
                    PCSrc  = PC_RELATIVE;
                    if (valid_branch_instruction)
                        PCWrite = branch_taken;
                end
                else if (is_jal_instruction) begin
                    ImmSrc  = 3'b100;
                    PCSrc   = PC_RELATIVE;
                    PCWrite = 1'b1;
                end
                else if (is_jalr_instruction) begin
                    ImmSrc  = 3'b000;
                    PCSrc   = PC_JALR;
                    PCWrite = 1'b1;
                end
            end

            MEM_ADDR: begin
                ALUSrcB    = 1'b1;
                ALUControl = ALU_ADD;
                ImmSrc     = is_store_instruction ? 3'b001 : 3'b000;
            end

            MEM_ACCESS: begin
                AdrSrc = 1'b1;
                if (is_store_instruction)
                    MemWrite = 1'b1;
            end

            LOAD_WB: begin
                AdrSrc    = 1'b1;
                ResultSrc = RESULT_MEM;
                if (is_load_instruction)
                    RegWrite = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
