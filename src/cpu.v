`include "alu.v"
`include "csr.v"
`include "ctrl_unit.v"
`include "ifu.v"
`include "lsu.v"
`include "regfile.v"

module CPU
 #( parameter XLEN = 32
 )( input clk, rstl
  , input  [XLEN-1:0] rom_data, mem_dout
  , output [XLEN-1:0] rom_addr, mem_din, mem_addr
  , output [XLEN/8-1:0] mem_r, mem_w
 );

    reg [XLEN-1:0] inst;
    reg [XLEN-1:0] pc;

    // -- Decoded instruction
    wire [XLEN-1:0] i_imm, s_imm, u_imm, b_imm, j_imm;
    wire sign = inst[31];
    assign i_imm = {{(XLEN-11){sign}}, inst[30:20]};
    assign s_imm = {{(XLEN-11){sign}}, inst[30:25], inst[11:7]};
    assign u_imm = {sign, inst[30:12], 12'b0};
    assign b_imm = {{(XLEN-12){sign}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign j_imm = {{(XLEN-20){sign}},
        inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [2:0] fn3 = inst[14:12];
    wire [4:0] rs1 = inst[19:15];
    wire [4:0] rs2 = inst[24:20];
    wire [4:0] rd  = inst[11:7];

    wire [11:0] csr_addr = inst[31:20];

    // -- Subunit wiring
    wire rd_w, ld_upper, add_pc, jmp_reg;
    wire is_branch, is_jmp, is_load, is_store;
    wire exc_ecall, exc_break;
    wire is_mret;
    wire is_fence, is_fencei, is_csr;
    wire [XLEN-1:0] load_data;

    wire trap_pc;
    wire [XLEN-1:0] pc_ifu, pc_trap;
    reg  [XLEN-1:0] pc_next;

    wire [2:0] alu_op;
    wire alu_imm, alu_sub, alu_sra;
    wire eq, lt, ltu;

    wire [XLEN-1:0] rs1_out, rs2_out;
    wire [XLEN-1:0] alu_s1 = rs1_out;
    wire [XLEN-1:0] alu_s2 = alu_imm ? (is_store ? s_imm : i_imm) : rs2_out;
    wire [XLEN-1:0] alu_out;

    wire csr_zimm, csr_w, csr_set, csr_clr;
    wire [XLEN-1:0] csr_dout;
    wire [XLEN-1:0] csr_din = csr_zimm ? {{XLEN-5{1'b0}}, rs1} : rs1_out;

    reg [XLEN-1:0] rd_in;
    always @* begin // rd_in
        if      (ld_upper) rd_in = u_imm;
        else if (add_pc)   rd_in = pc + u_imm;
        else if (is_jmp)   rd_in = pc + 4;
        else if (is_load)  rd_in = load_data;
        else if (is_csr)
            if      (csr_set) rd_in = csr_dout | csr_din;
            else if (csr_clr) rd_in = csr_dout & ~csr_din;
            else              rd_in = csr_dout;
        else               rd_in = alu_out;
    end

    assign mem_addr = alu_out; // rs1_out + s_imm
    assign mem_din  = rs2_out;
    assign rom_addr = pc_next;

    // -- Subunits
    RegFile #(XLEN) regs
      (.clk(clk), .rd_w(rd_w),
       .rd(rd), .rs1(rs1), .rs2(rs2),
       .rd_in(rd_in), .rs1_out(rs1_out), .rs2_out(rs2_out));

    CtrlUnit #(XLEN) cu
      (.inst(inst),
       .alu_imm(alu_imm), .alu_op(alu_op),
       .alu_sub(alu_sub), .alu_sra(alu_sra),
       .rd_w(rd_w), .add_pc(add_pc), .ld_upper(ld_upper), .jmp_reg(jmp_reg),
       .is_branch(is_branch), .is_jmp(is_jmp),
       .is_load(is_load), .is_store(is_store),
       .is_fence(is_fence), .is_fencei(is_fencei), .is_csr(is_csr),
       .is_mret(is_mret),
       .exc_ecall(exc_ecall), .exc_break(exc_break),
       .csr_zimm(csr_zimm),
       .csr_w(csr_w), .csr_set(csr_set), .csr_clr(csr_clr));

    ALU #(XLEN) alu
      (.s1(alu_s1), .s2(alu_s2), .out(alu_out),
       .op(alu_op), .sub(alu_sub), .sra(alu_sra),
       .eq(eq), .lt(lt), .ltu(ltu));

    LSU #(XLEN) lsu
      (.is_load(is_load), .is_store(is_store), .fn3(fn3),
       .mem_dout(mem_dout), .mem_w(mem_w), .mem_r(mem_r),
       .load_data(load_data));

    IFU #(XLEN) ifu
      (.is_branch(is_branch), .is_jmp(is_jmp), .jmp_reg(jmp_reg),
       .eq(eq), .lt(lt), .ltu(ltu),
       .fn3(fn3), .alu_out(alu_out), .b_imm(b_imm), .j_imm(j_imm),
       .pc(pc), .pc_ifu(pc_ifu));

   CSRs #(XLEN) csr
     (.clk(clk), .rstl(rstl),
      .trap_pc(trap_pc), .pc_trap(pc_trap), .pc_now(pc),
      .csr_addr(csr_addr), .csr_w(csr_w),
      .exc_ecall(exc_ecall), .exc_break(exc_break),
      .is_mret(is_mret),
      .csr_din(csr_din), .csr_dout(csr_dout));

    always @(rstl)
        if (!rstl) pc_next = 'b0;

    always @*
        pc_next = trap_pc ? pc_trap : pc_ifu;

    always @(posedge clk) begin
        inst <= rom_data;
        pc   <= pc_next;
    end
endmodule
