`define ALU_IN1_RS1     0
`define ALU_IN1_I_IMM   1
`define ALU_IN1_U_IMM   2

`define ALU_IN2_RS2     0
`define ALU_IN2_PC      1

module CtrlUnit
  ( input      [6:0] opcode
  , output           rd_w, is_branch, is_jmp, link_reg
  , output reg [1:0] alu_in1
  , output reg       alu_in2
 );

    assign rd_w      = |{inst_type_r, inst_type_i,
                         inst_type_u, inst_type_j};
    assign is_branch = inst_type_b;
    assign is_jmp    = |{op_jal, op_jalr};
    assign link_reg  = op_jalr;

    always @* begin
        if (op_auipc)
            alu_in2 = `ALU_IN2_PC;
        else
            alu_in2 = `ALU_IN2_RS2;
    end

    always @* begin
        if (inst_type_i)
            alu_in1 = `ALU_IN1_I_IMM;
        else if (inst_type_u)
            alu_in1 = `ALU_IN1_U_IMM;
        else
            alu_in1 = `ALU_IN1_RS1;
    end

    wire
      inst_type_r = |{
        op_op
      },
      inst_type_i = |{
        op_jalr,
        op_load,
        op_opimm
      },
      inst_type_u = |{
        op_lui,
        op_auipc
      },
      inst_type_s = op_store,
      inst_type_b = op_branch,
      inst_type_j = op_jal;

    wire 
      op_lui     = (7'b0110111 == opcode),
      op_auipc   = (7'b0010111 == opcode),
      op_opimm   = (7'b0010111 == opcode),
      op_op      = (7'b0110011 == opcode),
      op_jal     = (7'b1101111 == opcode),
      op_jalr    = (7'b1100111 == opcode),
      op_branch  = (7'b1100011 == opcode),
      op_load    = (7'b0000011 == opcode),
      op_store   = (7'b0100011 == opcode),
      op_miscmem = (7'b0001111 == opcode),
      op_system  = (7'b1110011 == opcode);
endmodule
