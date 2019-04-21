module CtrlUnit
 #( parameter XLEN = 32
 )( input  [XLEN-1:0] inst
  , output [2:0]      alu_op
  , output            alu_imm
  , output            alu_sub, alu_sra
  , output            rd_w
  , output            ld_upper, add_pc, jmp_reg
  , output            is_branch, is_jmp, is_load, is_store
  , output            is_fence, is_fencei, is_csr
  , output            is_mret
  , output            exc_ecall, exc_break
  , output            csr_zimm, csr_w, csr_set, csr_clr
 );

    wire [6:0]  opcode = inst[6:0];
    wire [2:0]  fn3    = inst[14:12];
    wire [6:0]  fn7    = inst[31:25];
    wire [11:0] fn12   = inst[31:20];
    wire [4:0]  rd     = inst[11:7];
    wire [4:0]  rs1    = inst[19:15];

    wire
      op_lui     = (7'b0110111 == opcode),
      op_auipc   = (7'b0010111 == opcode),
      op_opimm   = (7'b0010011 == opcode),
      op_op      = (7'b0110011 == opcode),
      op_jal     = (7'b1101111 == opcode),
      op_jalr    = (7'b1100111 == opcode),
      op_branch  = (7'b1100011 == opcode),
      op_load    = (7'b0000011 == opcode),
      op_store   = (7'b0100011 == opcode),
      op_miscmem = (7'b0001111 == opcode),
      op_system  = (7'b1110011 == opcode),

      inst_type_r = |{
        op_op
      },
      inst_type_i = |{
        op_jalr,
        op_load,
        op_opimm
        // FENCE instructions not included
      },
      inst_type_u = |{
        op_lui,
        op_auipc
      },
      inst_type_b = op_branch,
      inst_type_j = op_jal,
      inst_type_s = op_store;

    assign alu_op    = (is_jmp || is_load || is_store) ? 3'b000 : fn3;
    assign alu_imm   = |{inst_type_i, inst_type_s};

    assign alu_sub   = op_op && (fn3 == 3'b000) && (fn7 == 7'b0100000);
    assign alu_sra   = (op_op || op_opimm) &&
                       (fn3 == 3'b101) && (fn7 == 7'b0100000);

    assign rd_w      = |{
        inst_type_r, inst_type_i, inst_type_u, inst_type_j,
        is_csr
    };
    assign ld_upper  = op_lui;
    assign add_pc    = op_auipc;
    assign jmp_reg   = op_jalr && (fn3 == 3'b000);

    assign is_branch = inst_type_b;
    assign is_jmp    = |{op_jal, op_jalr};
    assign is_load   = op_load;
    assign is_store  = op_store;

    assign is_fence  = op_miscmem && (fn3 == 3'b000); // TODO: currently noop
    assign is_fencei = op_miscmem && (fn3 == 3'b001); // TODO: currently noop

    wire   is_priv   = op_system && rs1 == 0 && fn3 == 0 && rd == 0;
    assign exc_ecall = is_priv && fn12 == 12'b000000000000;
    assign exc_break = is_priv && fn12 == 12'b000000000001;
    assign is_mret   = is_priv && fn12 == 12'b001100000010;

    assign is_csr    = op_system && (fn3 != 3'b000);
    assign csr_zimm  = is_csr && fn3[2];
    assign csr_w     = is_csr && fn3[1:0] == 2'b01;
    assign csr_set   = is_csr && fn3[1:0] == 2'b10;
    assign csr_clr   = is_csr && fn3[1:0] == 2'b11;
endmodule
