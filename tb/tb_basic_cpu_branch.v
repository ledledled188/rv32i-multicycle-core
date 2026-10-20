`timescale 1ns/1ps

module tb_basic_cpu_branch;

    reg clk;
    reg reset;
    integer errors;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_branch.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task check_register;
        input [4:0]      reg_number;
        input [31:0]     expected;
        input [8*10-1:0] name;
        begin
            if (dut.u_reg_file.registers[reg_number] !== expected) begin
                $display("FAIL %-10s x%0d=%08h expected=%08h",
                         name,
                         reg_number,
                         dut.u_reg_file.registers[reg_number],
                         expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %-10s x%0d=%08h",
                         name,
                         reg_number,
                         dut.u_reg_file.registers[reg_number]);
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        reset  = 1'b1;
        errors = 0;

        #12;
        reset = 1'b0;

        // The program ends in a self-branch, so extra cycles are harmless.
        repeat (150) @(posedge clk);
        #1;

        $display("");
        $display("========================================");
        $display("      BRANCH INTEGRATION RESULTS");
        $display("========================================");

        check_register(5'd1,  32'd5,        "SETUP");
        check_register(5'd2,  32'd5,        "SETUP");
        check_register(5'd3,  32'd10,       "SETUP");
        check_register(5'd4,  32'hFFFFFFFF, "SETUP");

        // Taken tests retain 1 because the following clear is skipped.
        // Not-taken tests become 2 because the following ADDI executes.
        check_register(5'd10, 32'd1, "BEQ-T");
        check_register(5'd11, 32'd2, "BEQ-NT");
        check_register(5'd12, 32'd1, "BNE-T");
        check_register(5'd13, 32'd2, "BNE-NT");
        check_register(5'd14, 32'd1, "BLT-T");
        check_register(5'd15, 32'd2, "BLT-NT");
        check_register(5'd16, 32'd1, "BGE-T");
        check_register(5'd17, 32'd2, "BGE-NT");
        check_register(5'd18, 32'd1, "BLTU-T");
        check_register(5'd19, 32'd2, "BLTU-NT");
        check_register(5'd20, 32'd1, "BGEU-T");
        check_register(5'd21, 32'd2, "BGEU-NT");

        // Reaching the sentinel proves control flow reached the program end.
        check_register(5'd31, 32'd123, "SENTINEL");
        check_register(5'd0,  32'd0,   "X0");

        $display("========================================");
        if (errors == 0)
            $display("ALL BRANCH INTEGRATION TESTS PASSED");
        else
            $display("BRANCH INTEGRATION FAILED: %0d error(s)", errors);
        $display("========================================");

        $finish;
    end

    // Print every branch decision at its resolution edge.
    always @(posedge clk) begin
        if (!reset && dut.state == 3'b100) begin
            $display("BRANCH time=%0t OldPC=%08h target=%08h funct3=%b BrUn=%b BrEq=%b BrLT=%b taken=%b",
                     $time,
                     dut.OldPC,
                     dut.BranchTarget,
                     dut.funct3,
                     dut.BrUn,
                     dut.BrEq,
                     dut.BrLT,
                     dut.PCWrite);
        end
    end

endmodule


