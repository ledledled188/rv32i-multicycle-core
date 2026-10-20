`timescale 1ns / 1ps

module crc_unit (
    input  wire [31:0] crc_in,
    input  wire [31:0] data_in,
    input  wire [3:0]  crc_op,
    output reg  [31:0] crc_out
);

    function [15:0] step_crc;
        input [15:0] current_crc;
        input [7:0]  byte_val;
        reg   [15:0] rem;
        integer i;
        begin
            rem = current_crc ^ (byte_val << 8);
            for (i = 0; i < 8; i = i + 1) begin
                if (rem[15])
                    rem = (rem << 1) ^ 16'h1021;
                else
                    rem = rem << 1;
            end
            step_crc = rem;
        end
    endfunction

    reg [15:0] res_b;
    reg [15:0] res_h;
    reg [15:0] res_w;
    reg [15:0] temp1;
    reg [15:0] temp2;
    reg [15:0] temp3;

    always @(*) begin
        // The official firmware treats the written hexadecimal value in
        // network order: 0x1234 is processed as byte 0x12, then byte 0x34.
        res_b = step_crc(crc_in[15:0], data_in[7:0]);

        temp1 = step_crc(crc_in[15:0], data_in[15:8]);
        res_h = step_crc(temp1, data_in[7:0]);

        temp1 = step_crc(crc_in[15:0], data_in[31:24]);
        temp2 = step_crc(temp1, data_in[23:16]);
        temp3 = step_crc(temp2, data_in[15:8]);
        res_w = step_crc(temp3, data_in[7:0]);

        case (crc_op)
            4'h0:    crc_out = {16'h0000, res_b};
            4'h1:    crc_out = {16'h0000, res_h};
            4'h2:    crc_out = {16'h0000, res_w};
            default: crc_out = 32'b0;
        endcase
    end

endmodule
