`include "vunit_defines.svh"
`include "common.sv"
`include "ifu.v"

module tb_IFU;
    localparam XLEN = `XLEN;

    logic rstl;
    logic is_branch, is_jmp, jmp_reg;
    logic eq, lt, ltu;
    logic [2:0] fn3;

    logic [XLEN-1:0] alu_out, b_imm, j_imm;
    logic [XLEN-1:0] pc;

    wire [XLEN-1:0] pc_next;

    // Used for storing a random PC offset.
    integer n;

    IFU ifu (.*);

    `TEST_SUITE begin
        `TEST_CASE_SETUP begin
            is_branch = 0;
            is_jmp    = 0;
            jmp_reg   = 0;

            n  = $random();
            pc = $urandom();
            #1;
        end

        `TEST_CASE("rstl pin") begin
            rstl = 1;
            #1 rstl = 0;
            #1 `CHECK_EQUAL(pc_next, 0);
        end

        `TEST_CASE("no jump or branch") begin
            `CHECK_EQUAL(pc_next, pc + 4);
        end

        `TEST_CASE("jal") begin
            is_jmp = 1;

            j_imm = n;
            #1 `CHECK_EQUAL(pc_next, pc + n);

            j_imm = -n;
            #1 `CHECK_EQUAL(pc_next, pc - n);
        end

        `TEST_CASE("jalr") begin
            is_jmp  = 1;
            jmp_reg = 1;

            alu_out = n;
            #1 `CHECK_EQUAL(pc_next, n);
        end

        `TEST_CASE("branch") begin
            is_branch = 1;

            `define test(fn, v, p)                            \
                fn3 = fn;                                     \
                ``v = ~p; #1 `CHECK_EQUAL(pc_next, pc + 4);   \
                ``v = p;                                      \
                b_imm = n;  #1 `CHECK_EQUAL(pc_next, pc + n); \
                b_imm = -n; #1 `CHECK_EQUAL(pc_next, pc - n);

              /* BEQ  */ `test(3'b000, eq,  1);
              /* BNE  */ `test(3'b001, eq,  0);
              /* BLT  */ `test(3'b100, lt,  1);
              /* BGE  */ `test(3'b101, lt,  0);
              /* BLTU */ `test(3'b110, ltu, 1);
              /* BGEU */ `test(3'b111, ltu, 0);

            `undef test
        end
    end
endmodule
