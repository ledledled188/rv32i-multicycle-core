`timescale 1ns/1ps

module tb_basic_cpu_checkpoint2;

    reg clk;
    reg reset;
    integer errors;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_checkpoint2.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task check_register;
        input [4:0]      reg_number;
        input [31:0]     expected;
        input [8*8-1:0]  instruction_name;
        begin
            if (dut.u_reg_file.registers[reg_number] !== expected) begin
                $display("FAIL %-8s x%0d=%08h expected=%08h",
                         instruction_name,
                         reg_number,
                         dut.u_reg_file.registers[reg_number],
                         expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %-8s x%0d=%08h",
                         instruction_name,
                         reg_number,
                         dut.u_reg_file.registers[reg_number]);
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        reset  = 1'b1;
        errors = 0;

        // Apply reset across at least one rising edge.
        #12;
        reset = 1'b0;

        // 22 instructions, four clock cycles per instruction.
        repeat (88) @(posedge clk);
        #1;

        $display("");
        $display("============================================");
        $display(" CHECKPOINT 2 FULL ALU INTEGRATION RESULTS");
        $display("============================================");

        // Setup values
        check_register(5'd1,  32'h0000000A, "SETUP"); // 10
        check_register(5'd2,  32'h00000003, "SETUP"); // 3
        check_register(5'd3,  32'hFFFFFFF0, "SETUP"); // -16

        // Register-register operations
        check_register(5'd4,  32'h0000000D, "ADD");
        check_register(5'd5,  32'h00000007, "SUB");
        check_register(5'd6,  32'h00000050, "SLL");
        check_register(5'd7,  32'h00000001, "SLT");
        check_register(5'd8,  32'h00000000, "SLTU");
        check_register(5'd9,  32'h00000009, "XOR");
        check_register(5'd10, 32'h1FFFFFFE, "SRL");
        check_register(5'd11, 32'hFFFFFFFE, "SRA");
        check_register(5'd12, 32'h0000000B, "OR");
        check_register(5'd13, 32'h00000002, "AND");

        // Immediate operations
        check_register(5'd14, 32'h00000005, "ADDI");
        check_register(5'd15, 32'h00000030, "SLLI");
        check_register(5'd16, 32'h00000001, "SLTI");
        check_register(5'd17, 32'h00000001, "SLTIU");
        check_register(5'd18, 32'h00000005, "XORI");
        check_register(5'd19, 32'h3FFFFFFC, "SRLI");
        check_register(5'd20, 32'hFFFFFFFC, "SRAI");
        check_register(5'd21, 32'h0000000B, "ORI");
        check_register(5'd22, 32'h00000002, "ANDI");

        // Architectural x0 must remain zero.
        check_register(5'd0, 32'h00000000, "X0");

        $display("============================================");
        if (errors == 0)
            $display("ALL CHECKPOINT 2 INTEGRATION TESTS PASSED");
        else
            $display("CHECKPOINT 2 FAILED: %0d error(s)", errors);
        $display("============================================");

        $finish;
    end

    // Concise execution trace: print only register write-back cycles.
    always @(posedge clk) begin
        if (!reset && dut.RegWrite) begin
            $display("WB time=%0t PC=%08h Instr=%08h Rd=x%0d Data=%08h ALUControl=%h",
                     $time,
                     dut.PC,
                     dut.Instr,
                     dut.Rd,
                     dut.WriteData,
                     dut.ALUControl);
        end
    end

endmodule


