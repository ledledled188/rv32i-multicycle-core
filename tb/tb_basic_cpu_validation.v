`timescale 1ns / 1ps

module tb_basic_cpu_validation;
    reg clk;
    reg reset;
    integer cycles;
    integer finished;

    localparam PASS_LOOP  = 32'h0040_03ec;
    localparam ERROR_LOOP = 32'h0040_03f4;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_validation.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("full_validation.vcd");
        $dumpvars(0, tb_basic_cpu_validation);

        clk = 1'b0;
        reset = 1'b1;
        cycles = 0;
        finished = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;

        while ((cycles < 5000) && !finished) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
            if ((dut.OldPC == PASS_LOOP) || (dut.OldPC == ERROR_LOOP))
                finished = 1;
        end

        $display("================================================");
        $display("OFFICIAL VALIDATION FIRMWARE RESULT");
        $display("================================================");
        $display("cycles = %0d", cycles);
        $display("PC     = %08h", dut.PC);
        $display("OldPC  = %08h", dut.OldPC);
        $display("x4     = %08h", dut.u_reg_file.registers[4]);

        if (!finished)
            $display("FAIL: timeout before PASS/ERROR completion loop");
        else if ((dut.OldPC == PASS_LOOP) &&
                 (dut.u_reg_file.registers[4] === 32'h0000_0000))
            $display("PASS: OFFICIAL VALIDATION FIRMWARE PASSED");
        else
            $display("FAIL: OFFICIAL VALIDATION FIRMWARE ENTERED ERROR LOOP");

        $display("================================================");
        $finish;
    end
endmodule


