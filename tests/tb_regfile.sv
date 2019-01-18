`include "vunit_defines.svh"
`include "common.sv"
`include "regfile.v"

module tb_RegFile;
    parameter XLEN = 32;
    reg clk, rd_w;

    reg  [4:0]      rs1, rs2, rd;
    reg  [XLEN-1:0] rd_in;
    wire [XLEN-1:0] rs1_out, rs2_out;

    RegFile #(XLEN) reg_file
        (clk, rd_w, rd, rs1, rs2, rd_in, rs1_out, rs2_out);

    `CLK_CREATE(clk);

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            `CLK_INIT(clk);
        end

        `TEST_CASE("x0 is set to 0") begin
            rs1 <= 0;
            rs2 <= 0;
            #1ns
            `CHECK_EQUAL(0, rs1_out);
            `CHECK_EQUAL(0, rs2_out);
        end

        `TEST_CASE("writing to x0 does nothing") begin
            rd    <= 0;
            rs1   <= 0;
            rd_w  <= 1;
            rd_in <= $urandom;

            `CYCLE_CLK;
            `CHECK_EQUAL(0, rs1_out);
        end

        `TEST_CASE("write works for registers x1 to x31") begin
            rd_w <= 1;

            for (int i = 1; i < 32; ++i) begin
                rd  <= i;
                rs1 <= i;
                rs2 <= i;
                rd_in <= $urandom;
                `CYCLE_CLK;
                `CHECK_EQUAL(rs1_out, rd_in);
                `CHECK_EQUAL(rs2_out, rd_in);
            end
        end

        `TEST_CASE("register not written to when rd_w is 0") begin
            for (int i = 1; i < 32; ++i) begin
                rd    <= i;
                rs1   <= i;

                rd_w  <= 1;
                rd_in <= 0;
                `CYCLE_CLK;
                `CHECK_EQUAL(rs1_out, 0);

                rd_w  <= 0;
                rd_in <= $urandom;
                `CYCLE_CLK;
                `CHECK_EQUAL(rs1_out, 0);
            end
        end
    end
endmodule
