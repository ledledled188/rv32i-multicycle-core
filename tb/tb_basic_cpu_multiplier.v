`timescale 1ns / 1ps

module tb_basic_cpu_multiplier;
    reg clk;
    reg reset;
    integer errors;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_multiplier.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task check_reg;
        input [4:0] index;
        input [31:0] expected;
        input [8*24-1:0] label;
        begin
            if (dut.u_reg_file.registers[index] !== expected) begin
                $display("FAIL %-24s x%0d=%h expected=%h",
                         label, index, dut.u_reg_file.registers[index], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %-24s x%0d=%h",
                         label, index, dut.u_reg_file.registers[index]);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        errors = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;

        repeat (50) @(posedge clk);
        #1;

        $display("================================================");
        $display("CHECKPOINT 6 MULTIPLIER INTEGRATION RESULTS");
        $display("================================================");

        check_reg(5'd1,  32'h0000_0007, "setup operand 7");
        check_reg(5'd2,  32'h0000_0009, "setup operand 9");
        check_reg(5'd3,  32'h0000_003f, "MUL low result");
        check_reg(5'd4,  32'hffff_fffe, "signed operand -2");
        check_reg(5'd5,  32'h0000_0003, "setup operand 3");
        check_reg(5'd6,  32'hffff_ffff, "MULH signed high");
        check_reg(5'd8,  32'hffff_ffff, "unsigned max operand");
        check_reg(5'd9,  32'hffff_fffe, "MULHSU mixed high");
        check_reg(5'd10, 32'hffff_fffe, "MULHU unsigned high");
        check_reg(5'd0,  32'h0000_0000, "x0 remains zero");

        if (errors == 0)
            $display("ALL CHECKPOINT 6 MULTIPLIER INTEGRATION TESTS PASSED");
        else
            $display("CHECKPOINT 6 TESTS FAILED: %0d error(s)", errors);
        $display("================================================");
        $finish;
    end
endmodule


