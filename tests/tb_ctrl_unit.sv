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
    logic is_store;     \
    logic is_fence;     \
    logic is_fencei;    \
    logic is_csr;       \
    logic is_mret;      \
    logic exc_ecall;    \
    logic exc_break;    \
    logic csr_zimm;     \
    logic csr_w;        \
    logic csr_set;      \
    logic csr_clr;

`define TEST(n, i) alu_op: 3'bx, default:0, name:n, inst:i
`define T_REG(n) `TEST(n, I({n, " x0, x0, x0"}))
`define T_IMM(n) `TEST(n, I({n, " x0, x0, 0"}))
`define T_PRV(n) `TEST(n, I({n}))
`define T_MEM(n) `TEST(n, I({n, " x0, 0(x0)"}))
`define T_U(n) `TEST(n, I({n, " x0, 0"}))
`define T_CSR(n) `TEST(n, I({n, " x0, x0, mscratch"}))
`define T_CSRI(n) `TEST(n, I({n, " x0, 0, mscratch"}))
const struct {
  string            name;
  logic [31:0] inst;

  `DECL_CU_OUT

} tests [] = '{
// 'x acts as a don't care.
 '{`T_U("lui"),   rd_w:1, ld_upper:1}
,'{`T_U("auipc"), rd_w:1, add_pc:1}
,'{`T_U("jal"),   rd_w:1, is_jmp:1}
,'{`T_IMM("jalr"),  rd_w:1, is_jmp:1, jmp_reg:1, alu_imm:1, alu_op: 3'b000}

,'{`T_IMM("beq"),  is_branch:1}
,'{`T_IMM("bne"),  is_branch:1}
,'{`T_IMM("blt"),  is_branch:1}
,'{`T_IMM("bge"),  is_branch:1}
,'{`T_IMM("bltu"), is_branch:1}
,'{`T_IMM("bgeu"), is_branch:1}

,'{`T_MEM("lb"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`T_MEM("lh"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`T_MEM("lw"),  rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`T_MEM("lhu"), rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}
,'{`T_MEM("lbb"), rd_w:1, alu_imm:1, alu_op: 3'b000, is_load:1}

,'{`T_MEM("sb"), alu_imm:1, alu_op: 3'b000, is_store:1}
,'{`T_MEM("sh"), alu_imm:1, alu_op: 3'b000, is_store:1}
,'{`T_MEM("sw"), alu_imm:1, alu_op: 3'b000, is_store:1}

,'{`T_IMM("addi"),  rd_w:1, alu_imm:1, alu_op: 3'b000}
,'{`T_IMM("slti"),  rd_w:1, alu_imm:1, alu_op: 3'b010}
,'{`T_IMM("sltiu"), rd_w:1, alu_imm:1, alu_op: 3'b011}
,'{`T_IMM("xori"),  rd_w:1, alu_imm:1, alu_op: 3'b100}
,'{`T_IMM("ori"),   rd_w:1, alu_imm:1, alu_op: 3'b110}
,'{`T_IMM("andi"),  rd_w:1, alu_imm:1, alu_op: 3'b111}
,'{`T_IMM("slli"),  rd_w:1, alu_imm:1, alu_op: 3'b001}
,'{`T_IMM("srli"),  rd_w:1, alu_imm:1, alu_op: 3'b101}
,'{`T_IMM("srai"),  rd_w:1, alu_imm:1, alu_op: 3'b101, alu_sra:1}

,'{`T_REG("add"),  rd_w:1, alu_op: 3'b000}
,'{`T_REG("sub"),  rd_w:1, alu_op: 3'b000, alu_sub:1}
,'{`T_REG("sll"),  rd_w:1, alu_op: 3'b001}
,'{`T_REG("slt"),  rd_w:1, alu_op: 3'b010}
,'{`T_REG("sltu"), rd_w:1, alu_op: 3'b011}
,'{`T_REG("xor"),  rd_w:1, alu_op: 3'b100}
,'{`T_REG("srl"),  rd_w:1, alu_op: 3'b101}
,'{`T_REG("sra"),  rd_w:1, alu_op: 3'b101, alu_sra:1}
,'{`T_REG("or"),   rd_w:1, alu_op: 3'b110}
,'{`T_REG("and"),  rd_w:1, alu_op: 3'b111}

,'{`T_IMM("fence"),  is_fence:1}  // TODO: still noop
,'{`T_IMM("fencei"), is_fencei:1} // TODO: still noop

,'{`T_PRV("mret"),   is_mret:1}
,'{`T_PRV("ecall"),  exc_ecall:1}
,'{`T_PRV("ebreak"), exc_break:1}

,'{`T_CSR("csrrw"),   rd_w:1, is_csr:1, csr_w:1}
,'{`T_CSR("csrrs"),   rd_w:1, is_csr:1, csr_set:1}
,'{`T_CSR("csrrc"),   rd_w:1, is_csr:1, csr_clr:1}
,'{`T_CSRI("csrrwi"), rd_w:1, is_csr:1, csr_w:1,   csr_zimm:1}
,'{`T_CSRI("csrrsi"), rd_w:1, is_csr:1, csr_set:1, csr_zimm:1}
,'{`T_CSRI("csrrci"), rd_w:1, is_csr:1, csr_clr:1, csr_zimm:1}
};
`undef TEST
`undef T_REG
`undef T_IMM
`undef T_MEM
`undef T_U
`undef T_CSR
`undef T_CSRI

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
      `define CHECK(s) \
        if (tests[testnum].``s !== 'x) `CHECK_EQUAL(``s, tests[testnum].``s);

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
        `CHECK(is_csr);
        `CHECK(is_mret);
        `CHECK(exc_ecall);
        `CHECK(exc_break);
        `CHECK(csr_zimm);
        `CHECK(csr_w);
        `CHECK(csr_set);
        `CHECK(csr_clr);
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
