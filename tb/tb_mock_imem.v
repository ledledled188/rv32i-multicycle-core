`timescale 1ns / 1ps

module tb_mock_imem;
    reg clk;
    reg reset;
    integer cycles;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_simple_mock.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("mock_imem.vcd");
        $dumpvars(0, tb_mock_imem);

        clk = 1'b0;
        reset = 1'b1;
        cycles = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;

        $display("============================================================");
        $display("   CHAMPIONCHIP RVBL-2: SIMPLE MOCK OPENLANE TESTBENCH      ");
        $display("============================================================");
        $display("Executing Program:");
        $display("  [0x00400000] addi x5, x0, 10");
        $display("  [0x00400004] addi x6, x0, 5");
        $display("  [0x00400008] add  x7, x5, x6");
        $display("------------------------------------------------------------");

        while (cycles < 20) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        $display("Simulation Finished at Cycle %0d", cycles);
        $display("Register States:");
        $display("  x5 = %0d (Expected 10)", dut.u_reg_file.registers[5]);
        $display("  x6 = %0d (Expected 5)",  dut.u_reg_file.registers[6]);
        $display("  x7 = %0d (Expected 15)", dut.u_reg_file.registers[7]);
        $display("------------------------------------------------------------");

        if (dut.u_reg_file.registers[5] == 10 &&
            dut.u_reg_file.registers[6] == 5  &&
            dut.u_reg_file.registers[7] == 15) begin
            $display(">>> [PASS] EXPECTED RESULT: x7 = 15 (MATCH OK) <<<");
        end else begin
            $display(">>> [FAIL] EXPECTED RESULT: x7 = 15 (MISMATCH) <<<");
        end
        $display("============================================================");

        $finish;
    end

endmodule
