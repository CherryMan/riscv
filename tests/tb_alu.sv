`include "vunit_defines.svh"
`include "alu.v"


module tb_ALU;
    parameter XLEN = 32;
    parameter MASK = (2^XLEN - 1);

    reg             sub, sra;
    reg  [2:0]      op;
    wire [XLEN-1:0] a, b;
    wire [XLEN-1:0] out;

    int x, y;

    assign a = x;
    assign b = y;

    ALU #(XLEN) alu
        (a, b, op, sub, sra, out);

    `TEST_SUITE begin
        `TEST_CASE_SETUP begin
            x = $urandom & MASK;
            y = $urandom & MASK;
        end

        `TEST_CASE("add and sub") begin
            op = 3'b000;
            sub = 0;
            #1ns `CHECK_EQUAL(out, x + y);

            sub = 1;
            #1ns `CHECK_EQUAL(out, x - y);
        end

        `TEST_CASE("shift ops") begin
            for (y = 0; y < 32; ++y) begin
                op = 3'b001; // SLL
                #1ns `CHECK_EQUAL(out, x << y);

                op = 3'b101; // SRL/SRA
                sra = 0;
                #1ns `CHECK_EQUAL(out, x >> y);
                sra = 1;
                #1ns `CHECK_EQUAL(out, x >>> y);
            end
        end

        `TEST_CASE("slt") begin
            op = 3'b010;
            #1ns `CHECK_EQUAL(out, $signed(x) < $signed(y));

            x = -1;
            y = 0;
            #1ns `CHECK_EQUAL(out, 1);
        end

        `TEST_CASE("sltu") begin
            op = 3'b011;
            #1ns `CHECK_EQUAL(out, x < y);

            x = -1 & MASK;
            y = 0;
            #1ns `CHECK_EQUAL(out, 0);
        end

        `TEST_CASE("xor") begin
            op = 3'b100;
            #1ns `CHECK_EQUAL(out, x ^ y);
        end

        `TEST_CASE("or") begin
            op = 3'b110;
            #1ns `CHECK_EQUAL(out, x | y);
        end

        `TEST_CASE("and") begin
            op = 3'b111;
            #1ns `CHECK_EQUAL(out, x & y);
        end
    end
endmodule
