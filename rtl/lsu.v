`timescale 1ns / 1ps

module lsu (
    input  wire [31:0] core_data_o,
    input  wire [31:0] core_address_o,
    input  wire [2:0]  op_size_o,
    output reg  [31:0] core_data_i,

    input  wire [31:0] mem_data_o,
    output reg  [31:0] mem_data_i,
    output wire [31:0] mem_address_i,
    output reg  [3:0]  byte_write_i
);

    wire [1:0] byte_offset = core_address_o[1:0];

    localparam [2:0] OP_BYTE        = 3'b000;
    localparam [2:0] OP_HALF        = 3'b001;
    localparam [2:0] OP_WORD        = 3'b010;
    localparam [2:0] OP_BYTE_UNS    = 3'b100;
    localparam [2:0] OP_HALF_UNS    = 3'b101;

    assign mem_address_i = core_address_o;

    always @(*) begin
        mem_data_i   = 32'h00000000;
        byte_write_i = 4'b0000;

        case (op_size_o)
            OP_BYTE: begin
                case (byte_offset)
                    2'b00: begin
                        mem_data_i   = {24'b0, core_data_o[7:0]};
                        byte_write_i = 4'b0001;
                    end
                    2'b01: begin
                        mem_data_i   = {16'b0, core_data_o[7:0], 8'b0};
                        byte_write_i = 4'b0010;
                    end
                    2'b10: begin
                        mem_data_i   = {8'b0, core_data_o[7:0], 16'b0};
                        byte_write_i = 4'b0100;
                    end
                    2'b11: begin
                        mem_data_i   = {core_data_o[7:0], 24'b0};
                        byte_write_i = 4'b1000;
                    end
                endcase
            end

            OP_HALF: begin
                case (byte_offset)
                    2'b00: begin
                        mem_data_i   = {16'b0, core_data_o[15:0]};
                        byte_write_i = 4'b0011;
                    end
                    2'b10: begin
                        mem_data_i   = {core_data_o[15:0], 16'b0};
                        byte_write_i = 4'b1100;
                    end
                    default: begin
                        // SH must be aligned to a two-byte boundary.
                        mem_data_i   = 32'b0;
                        byte_write_i = 4'b0000;
                    end
                endcase
            end

            OP_WORD: begin
                if (byte_offset == 2'b00) begin
                    mem_data_i   = core_data_o;
                    byte_write_i = 4'b1111;
                end
            end

            default: begin
                mem_data_i   = 32'h00000000;
                byte_write_i = 4'b0000;
            end
        endcase
    end

    always @(*) begin
        core_data_i = 32'h00000000;

        case (op_size_o)
            OP_BYTE: begin
                case (byte_offset)
                    2'b00: core_data_i = {{24{mem_data_o[7]}},  mem_data_o[7:0]};
                    2'b01: core_data_i = {{24{mem_data_o[15]}}, mem_data_o[15:8]};
                    2'b10: core_data_i = {{24{mem_data_o[23]}}, mem_data_o[23:16]};
                    2'b11: core_data_i = {{24{mem_data_o[31]}}, mem_data_o[31:24]};
                endcase
            end

            OP_BYTE_UNS: begin
                case (byte_offset)
                    2'b00: core_data_i = {24'b0, mem_data_o[7:0]};
                    2'b01: core_data_i = {24'b0, mem_data_o[15:8]};
                    2'b10: core_data_i = {24'b0, mem_data_o[23:16]};
                    2'b11: core_data_i = {24'b0, mem_data_o[31:24]};
                endcase
            end

            OP_HALF: begin
                case (byte_offset)
                    2'b00: core_data_i = {{16{mem_data_o[15]}}, mem_data_o[15:0]};
                    2'b10: core_data_i = {{16{mem_data_o[31]}}, mem_data_o[31:16]};
                    default: core_data_i = 32'b0;
                endcase
            end

            OP_HALF_UNS: begin
                case (byte_offset)
                    2'b00: core_data_i = {16'b0, mem_data_o[15:0]};
                    2'b10: core_data_i = {16'b0, mem_data_o[31:16]};
                    default: core_data_i = 32'b0;
                endcase
            end

            OP_WORD: begin
                if (byte_offset == 2'b00)
                    core_data_i = mem_data_o;
            end

            default: begin
                core_data_i = 32'b0;
            end
        endcase
    end

endmodule
