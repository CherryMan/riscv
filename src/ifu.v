module IFU
 #( parameter XLEN = 32
 )( input      rstl
  , input      [XLEN-1:0] pc
  , input      is_branch, is_jmp, jmp_reg
  , input      eq, lt, ltu
  , input      [2:0] fn3
  , input      [XLEN-1:0] alu_out, b_imm, j_imm
  , output reg [XLEN-1:0] pc_next
 );

    wire ne  = ~eq;
    wire ge  = ~lt;
    wire geu = ~ltu;

    reg branch_taken;

    always @(rstl)
        if (!rstl) pc_next = 'b0;

    always @* begin // branch_taken
        case (fn3)
            3'b000: /* BEQ  */ branch_taken = eq;
            3'b001: /* BNE  */ branch_taken = ne;
            3'b100: /* BLT  */ branch_taken = lt;
            3'b101: /* BGE  */ branch_taken = ge;
            3'b110: /* BLTU */ branch_taken = ltu;
            3'b111: /* BGEU */ branch_taken = geu;
            default:           branch_taken = 0;
        endcase
    end

    always @* begin // pc_offset
        if (is_jmp)
            pc_next = jmp_reg ? alu_out : pc + j_imm;
        else if (is_branch & branch_taken)
            pc_next = pc + b_imm;
        else
            pc_next = pc + 4;
    end
endmodule
