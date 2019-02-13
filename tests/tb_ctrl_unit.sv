`include "vunit_defines.svh"
`include "asm.sv"
`include "common.sv"
`include "ctrl_unit.v"

// Declare all CtrlUnit outputs, to avoid
// repeating in two places.
// If an output is added or removed, it must be updated here
// and under the test() task.
`define DECL_CU_OUT     \
    logic [2:0] alu_op; \
    logic alu_imm;      \
    logic alu_sub;      \
    logic alu_sra;      \
    logic rd_w;         \
    logic ld_upper;     \
    logic add_pc;       \
    logic jmp_reg;      \
    logic is_branch;    \
    logic is_jmp;       \
    logic is_load;      \
    logic is_store;

`define TEST(n, i) alu_op: 3'bx, default:0, name:n, inst:i
`define TESTR(n) `TEST(n, callr(n, "x0", "x0", "x0"))
`define TESTI(n) `TEST(n, calli(n, "x0", "x0", 0))
`define TESTS(n) `TEST(n, calls(n, "x0", "x0", 0))
`define TESTB(n) `TEST(n, callb(n, "x0", "x0", 0))
`define TESTU(n) `TEST(n, callu(n, "x0", 0))
`define TESTJ(n) `TEST(n, callj(n, "x0", 0))
localparam  struct {
  string            name;
  logic [`XLEN-1:0] inst;

  `DECL_CU_OUT

} tests [] = '{
// 'x acts as a don't care.
 '{`TESTU("lui"),   rd_w:1, ld_upper:1}
,'{`TESTU("auipc"), rd_w:1, add_pc:1}
,'{`TESTJ("jal"),   rd_w:1, is_jmp:1}
,'{`TESTI("jalr"),  rd_w:1, is_jmp:1, jmp_reg:1, alu_imm:1, alu_op: 3'b000}

,'{`TESTB("beq"),  is_branch:1}
,'{`TESTB("bne"),  is_branch:1}
,'{`TESTB("blt"),  is_branch:1}
,'{`TESTB("bge"),  is_branch:1}
,'{`TESTB("bltu"), is_branch:1}
,'{`TESTB("bgeu"), is_branch:1}

,'{`TESTI("lb"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`TESTI("lh"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`TESTI("lw"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`TESTI("lhu"), rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`TESTI("lbb"), rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}

,'{`TESTS("sb"), alu_imm:1, alu_op: 3'b000, is_store:1}
,'{`TESTS("sh"), alu_imm:1, alu_op: 3'b000, is_store:1}
,'{`TESTS("sw"), alu_imm:1, alu_op: 3'b000, is_store:1}

,'{`TESTI("addi"),  rd_w:1, alu_imm:1, alu_op: 3'b000}
,'{`TESTI("slti"),  rd_w:1, alu_imm:1, alu_op: 3'b010}
,'{`TESTI("sltiu"), rd_w:1, alu_imm:1, alu_op: 3'b011}
,'{`TESTI("xori"),  rd_w:1, alu_imm:1, alu_op: 3'b100}
,'{`TESTI("ori"),   rd_w:1, alu_imm:1, alu_op: 3'b110}
,'{`TESTI("andi"),  rd_w:1, alu_imm:1, alu_op: 3'b111}
,'{`TESTI("slli"),  rd_w:1, alu_imm:1, alu_op: 3'b001}
,'{`TESTI("srli"),  rd_w:1, alu_imm:1, alu_op: 3'b101}
,'{`TESTI("srai"),  rd_w:1, alu_imm:1, alu_op: 3'b101, alu_sra:1}

,'{`TESTR("add"),  rd_w:1, alu_op: 3'b000}
,'{`TESTR("sub"),  rd_w:1, alu_op: 3'b000, alu_sub:1}
,'{`TESTR("sll"),  rd_w:1, alu_op: 3'b001}
,'{`TESTR("slt"),  rd_w:1, alu_op: 3'b010}
,'{`TESTR("sltu"), rd_w:1, alu_op: 3'b011}
,'{`TESTR("xor"),  rd_w:1, alu_op: 3'b100}
,'{`TESTR("srl"),  rd_w:1, alu_op: 3'b101}
,'{`TESTR("sra"),  rd_w:1, alu_op: 3'b101, alu_sra:1}
,'{`TESTR("or"),   rd_w:1, alu_op: 3'b110}
,'{`TESTR("and"),  rd_w:1, alu_op: 3'b111}
};
`undef TEST
`undef TESTR
`undef TESTI
`undef TESTS
`undef TESTB
`undef TESTU
`undef TESTJ

module tb_CtrlUnit;
    localparam XLEN = `XLEN;

    reg [XLEN-1:0] inst;

    `DECL_CU_OUT;

    // .* used to avoid repetition.
    CtrlUnit cu (.*);

    task test(integer testnum);
      $display("Testing instruction: %s", tests[testnum].name.toupper());

      // If the variable is eq to 'x, it is treated as a don't care,
      // and thus ignored.
      `define CHECK(s) if (tests[testnum].``s !== 'x) \
        `CHECK_EQUAL(``s, tests[testnum].``s);

        `CHECK(alu_op);
        `CHECK(alu_imm);
        `CHECK(alu_sub);
        `CHECK(alu_sra);
        `CHECK(rd_w);
        `CHECK(ld_upper);
        `CHECK(add_pc);
        `CHECK(jmp_reg);
        `CHECK(is_branch);
        `CHECK(is_jmp);
        `CHECK(is_load);
        `CHECK(is_store);
      `undef CHECK
    endtask

    `TEST_SUITE begin
        `TEST_CASE("instructions") begin
            foreach(tests[i]) begin
                inst = tests[i].inst;
                #1ns test(i);
            end
        end
    end
endmodule
