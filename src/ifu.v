module IFU
 #( parameter XLEN = 32
 )( input  [XLEN-1:0] pc
  , input  is_branch, is_jmp, jmp_reg
  , input  eq, lt, ltu
  , input  [2:0] fn3
  , input  [XLEN-1:0] alu_out, b_imm, j_imm
  , output [XLEN-1:0] pc_next
 );

    wire ne  = ~eq;
    wire ge  = ~lt;
    wire geu = ~ltu;

    reg branch_taken;
    reg  [XLEN-1:0] pc_offset;

    assign pc_next = pc + pc_offset;

    always @* begin // branch_taken
        case (fn3)
            3'b000: /* BEQ  */ branch_taken = eq;
            3'b001: /* BNE  */ branch_taken = ne;
            3'b100: /* BLT  */ branch_taken = lt;
            3'b101: /* BGE  */ branch_taken = ge;
            3'b110: /* BLTU */ branch_taken = ltu;
            3'b111: /* BGEU */ branch_taken = geu;
        endcase
    end

    always @* begin // pc_offset
        if (is_jmp)
            pc_offset = jmp_reg ? alu_out : j_imm;
        else if (is_branch & branch_taken)
            pc_offset = b_imm;
        else
            pc_offset = 4;
    end
endmodule
