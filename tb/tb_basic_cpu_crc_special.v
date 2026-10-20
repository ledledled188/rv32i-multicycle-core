`timescale 1ns / 1ps

module tb_basic_cpu_crc_special;
    reg clk;
    reg reset;
    integer errors;

    basic_cpu #(
        .MEM_INIT_FILE("firmware/firmware_crc_special.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task check_reg;
        input [4:0] index;
        input [31:0] expected;
        input [8*28-1:0] label;
        begin
            if (dut.u_reg_file.registers[index] !== expected) begin
                $display("FAIL %-28s x%0d=%h expected=%h",
                         label, index, dut.u_reg_file.registers[index], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %-28s x%0d=%h",
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

        repeat (110) @(posedge clk);
        #1;

        $display("================================================");
        $display("CHECKPOINT 7 CRC + SPECIAL INTEGRATION RESULTS");
        $display("================================================");

        check_reg(5'd3,  32'h0000_c782, "CRCB one byte");
        check_reg(5'd5,  32'h0000_3dba, "CRCH two bytes");
        check_reg(5'd11, 32'h0000_5349, "CRCW four bytes");

        check_reg(5'd12, 32'h1234_5000, "LUI upper immediate");
        check_reg(5'd13, 32'h0040_0028, "AUIPC old PC plus U-imm");
        check_reg(5'd14, 32'h0040_0030, "JAL link address");
        check_reg(5'd15, 32'h0000_002a, "JAL skipped instruction");
        check_reg(5'd16, 32'h0040_0049, "JALR odd source address");
        check_reg(5'd17, 32'h0040_0044, "JALR link address");
        check_reg(5'd18, 32'h0000_0018, "JALR clears target bit 0");

        // Reaching x19 proves FENCE, ECALL, and EBREAK retired without
        // corrupting architectural state in this trap-less core.
        check_reg(5'd19, 32'h0000_0007, "system/sync continuation");
        check_reg(5'd0,  32'h0000_0000, "x0 remains zero");

        if (errors == 0)
            $display("ALL CHECKPOINT 7 CRC + SPECIAL TESTS PASSED");
        else
            $display("CHECKPOINT 7 TESTS FAILED: %0d error(s)", errors);
        $display("================================================");
        $finish;
    end
endmodule


