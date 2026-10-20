module basic_cpu #(
    parameter MEM_INIT_FILE = "firmware.hex"
)(
    input wire clk,
    input wire reset
);

    wire [31:0] PC;
    wire [31:0] PCNext;
    wire [31:0] PCPlus4;
    wire [31:0] OldPCPlus4;
    wire [31:0] PCRelativeTarget;
    // Compatibility alias retained for the Checkpoint 3 branch testbench.
    wire [31:0] BranchTarget;
    wire [31:0] JALRTarget;
    wire [31:0] Adr;
    wire [31:0] ReadData;
    wire [31:0] Instr;
    reg  [31:0] OldPC;

    wire [6:0]  op;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [11:0] funct12;
    wire [4:0]  Rs1;
    wire [4:0]  Rs2;
    wire [4:0]  Rd;

    wire [31:0] RD1;
    wire [31:0] RD2;
    reg  [31:0] WriteData;
    wire [31:0] ImmExt;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] ALUResult;
    reg  [31:0] ALUOut;
    wire [31:0] MulResult;
    wire [31:0] CRCResult;

    wire        PCWrite;
    wire        IRWrite;
    wire        RegWrite;
    wire        ALUSrcA;
    wire        ALUSrcB;
    wire [3:0]  ALUControl;
    wire [3:0]  MulControl;
    wire [3:0]  CRCControl;
    wire [2:0]  ImmSrc;
    wire [2:0]  state;

    wire       BrUn;
    wire       BrEq;
    wire       BrLT;
    wire [1:0] PCSrc;

    wire       AdrSrc;
    wire       MemWrite;
    wire [2:0] ResultSrc;

    wire [31:0] LoadData;
    wire [31:0] MemWriteData;
    wire [31:0] MemAddress;
    wire [3:0]  ByteWrite;

    wire [21:0] IMEMAdr;
    wire [31:0] IMEMReadData;
    wire [12:0] DMEMAdr;
    wire        DMEMWriteEnable;
    wire        DMEMOutputEnable;
    wire [3:0]  DMEMByteWrite;
    wire [31:0] DMEMWriteData;
    wire [31:0] DMEMReadData;

    localparam EXECUTE  = 3'b010;
    localparam MEM_ADDR = 3'b101;

    localparam RESULT_ALU = 3'b000;
    localparam RESULT_MEM = 3'b001;
    localparam RESULT_MUL = 3'b010;
    localparam RESULT_CRC = 3'b011;
    localparam RESULT_PC4 = 3'b100;

    assign op      = Instr[6:0];
    assign Rd      = Instr[11:7];
    assign funct3  = Instr[14:12];
    assign Rs1     = Instr[19:15];
    assign Rs2     = Instr[24:20];
    assign funct7  = Instr[31:25];
    assign funct12 = Instr[31:20];

    assign PCPlus4          = PC + 32'd4;
    assign OldPCPlus4       = OldPC + 32'd4;
    assign PCRelativeTarget = OldPC + ImmExt;
    assign BranchTarget     = PCRelativeTarget;
    assign JALRTarget       = (RD1 + ImmExt) & 32'hFFFF_FFFE;
    assign PCNext = (PCSrc == 2'b01) ? PCRelativeTarget :
                    (PCSrc == 2'b10) ? JALRTarget : PCPlus4;

    assign Adr = AdrSrc ? MemAddress : PC;

    always @(*) begin
        case (ResultSrc)
            RESULT_ALU: WriteData = ALUOut;
            RESULT_MEM: WriteData = LoadData;
            RESULT_MUL: WriteData = MulResult;
            RESULT_CRC: WriteData = CRCResult;
            RESULT_PC4: WriteData = OldPCPlus4;
            default:    WriteData = 32'b0;
        endcase
    end

    program_counter u_pc (
        .clk    (clk),
        .reset  (reset),
        .PCWrite(PCWrite),
        .PCNext (PCNext),
        .PC     (PC)
    );

    instruction_register u_ir (
        .clk    (clk),
        .reset  (reset),
        .IRWrite(IRWrite),
        .InstrIn(ReadData),
        .Instr  (Instr)
    );

    always @(posedge clk) begin
        if (reset)
            OldPC <= 32'h0040_0000;
        else if (IRWrite)
            OldPC <= PC;
    end

    control_unit u_control (
        .clk       (clk),
        .reset     (reset),
        .op        (op),
        .funct3    (funct3),
        .funct7    (funct7),
        .funct12   (funct12),
        .BrEq      (BrEq),
        .BrLT      (BrLT),
        .PCWrite   (PCWrite),
        .IRWrite   (IRWrite),
        .RegWrite  (RegWrite),
        .ALUSrcA   (ALUSrcA),
        .ALUSrcB   (ALUSrcB),
        .ALUControl(ALUControl),
        .MulControl(MulControl),
        .CRCControl(CRCControl),
        .ImmSrc    (ImmSrc),
        .BrUn      (BrUn),
        .PCSrc     (PCSrc),
        .AdrSrc    (AdrSrc),
        .MemWrite  (MemWrite),
        .ResultSrc (ResultSrc),
        .state     (state)
    );

    reg_file u_reg_file (
        .clk      (clk),
        .reset    (reset),
        .RegWrite (RegWrite),
        .Rs1      (Rs1),
        .Rs2      (Rs2),
        .Rd       (Rd),
        .WriteData(WriteData),
        .RD1      (RD1),
        .RD2      (RD2)
    );

    imm_gen u_imm_gen (
        .Instr (Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    branch_comp u_branch_comp (
        .RD1 (RD1),
        .RD2 (RD2),
        .BrUn(BrUn),
        .BrEq(BrEq),
        .BrLT(BrLT)
    );

    assign SrcA = ALUSrcA ? OldPC : RD1;
    assign SrcB = ALUSrcB ? ImmExt : RD2;

    alu u_alu (
        .SrcA      (SrcA),
        .SrcB      (SrcB),
        .ALUControl(ALUControl),
        .ALUResult (ALUResult)
    );

    multiplier u_multiplier (
        .a     (RD1),
        .b     (RD2),
        .mul_op(MulControl),
        .result(MulResult)
    );

    crc_unit u_crc (
        // Official validation firmware uses: crc* rd, data, previous_crc.
        .crc_in (RD2),
        .data_in(RD1),
        .crc_op (CRCControl),
        .crc_out(CRCResult)
    );

    always @(posedge clk) begin
        if (reset)
            ALUOut <= 32'b0;
        else if ((state == EXECUTE) || (state == MEM_ADDR))
            ALUOut <= ALUResult;
    end

    lsu u_lsu (
        .core_data_o   (RD2),
        .core_address_o(ALUOut),
        .op_size_o     (funct3),
        .core_data_i   (LoadData),
        .mem_data_o    (ReadData),
        .mem_data_i    (MemWriteData),
        .mem_address_i (MemAddress),
        .byte_write_i  (ByteWrite)
    );

    addr_decoder u_addr_decoder (
        .clk     (clk),
        .Adr     (Adr),
        .WE      (MemWrite),
        .BW      (ByteWrite),
        .WD      (MemWriteData),
        .DMEM_Adr(DMEMAdr),
        .DMEM_WE (DMEMWriteEnable),
        .DMEM_OE (DMEMOutputEnable),
        .DMEM_BW (DMEMByteWrite),
        .DMEM_WD (DMEMWriteData),
        .IMEM_Adr(IMEMAdr),
        .DMEM_RD (DMEMReadData),
        .IMEM_RD (IMEMReadData),
        .RD      (ReadData)
    );

    imem #(
        .ADDR_WIDTH   (22),
        .MEM_INIT_FILE(MEM_INIT_FILE)
    ) u_imem (
        .Adr(IMEMAdr),
        .RD (IMEMReadData)
    );

    dmem #(
        .ADDR_WIDTH(13)
    ) u_dmem (
        .clk(clk),
        .Adr(DMEMAdr),
        .WE (DMEMWriteEnable),
        .OE (DMEMOutputEnable),
        .BW (DMEMByteWrite),
        .WD (DMEMWriteData),
        .RD (DMEMReadData)
    );

endmodule
