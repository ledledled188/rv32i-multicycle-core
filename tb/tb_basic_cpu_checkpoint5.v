`timescale 1ns/1ps

module tb_basic_cpu_checkpoint5;
    reg clk;
    reg reset;
    integer errors;
    reg [31:0] memory_word_0;
    reg [31:0] memory_word_1;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_checkpoint5.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check_register;
        input [4:0] index;
        input [31:0] expected;
        input [8*18-1:0] label;
        reg [31:0] actual;
        begin
            if (index == 0)
                actual = 32'b0;
            else
                actual = dut.u_reg_file.registers[index];

            if (actual === expected)
                $display("PASS %-18s x%0d=%h", label, index, actual);
            else begin
                $display("FAIL %-18s x%0d=%h expected=%h",
                         label, index, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // The useful program needs 136 multicycle clocks. Leave extra margin.
        repeat (145) @(posedge clk);
        #1;

        memory_word_0 = {dut.u_dmem.mem3[0], dut.u_dmem.mem2[0],
                         dut.u_dmem.mem1[0], dut.u_dmem.mem0[0]};
        memory_word_1 = {dut.u_dmem.mem3[1], dut.u_dmem.mem2[1],
                         dut.u_dmem.mem1[1], dut.u_dmem.mem0[1]};

        $display("================================================");
        $display("CHECKPOINT 5 COMPLETE LSU INTEGRATION RESULTS");
        $display("================================================");

        check_register(5'd1,  32'h1001_0000, "DMEM address");
        check_register(5'd3,  32'h0000_0001, "LB positive lane 0");
        check_register(5'd4,  32'h0000_007F, "LB positive lane 1");
        check_register(5'd5,  32'hFFFF_FFFF, "LB sign lane 2");
        check_register(5'd6,  32'h0000_00FF, "LBU lane 2");
        check_register(5'd7,  32'hFFFF_FF80, "LB sign lane 3");
        check_register(5'd8,  32'h0000_0080, "LBU lane 3");
        check_register(5'd9,  32'h0000_7F01, "LH lower signed");
        check_register(5'd10, 32'h0000_7F01, "LHU lower");
        check_register(5'd11, 32'hFFFF_80FF, "LH upper signed");
        check_register(5'd12, 32'h0000_80FF, "LHU upper");
        check_register(5'd13, 32'h0000_1234, "SH source");
        check_register(5'd14, 32'h1234_1234, "SH lane result");
        check_register(5'd15, 32'h0000_1234, "SW/LW regression");

        if (memory_word_0 === 32'h1234_1234)
            $display("PASS DMEM word 0        value=%h", memory_word_0);
        else begin
            $display("FAIL DMEM word 0        value=%h expected=12341234", memory_word_0);
            errors = errors + 1;
        end

        if (memory_word_1 === 32'h0000_1234)
            $display("PASS DMEM word 1        value=%h", memory_word_1);
        else begin
            $display("FAIL DMEM word 1        value=%h expected=00001234", memory_word_1);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL CHECKPOINT 5 COMPLETE LSU TESTS PASSED");
        else
            $display("CHECKPOINT 5 TESTS FAILED: %0d error(s)", errors);

        $display("================================================");
        $finish;
    end
endmodule


