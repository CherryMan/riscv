/* This file provides utilities for assembling instructions.
 * Used for generating bit values for testing.
 */

`ifndef XLEN
`define XLEN 32
`endif

typedef enum {
    // Special type for load instructions,
    // because load instructions are written
    // differently than I-type instructions due
    // to the offset.
    L_TYPE,

    // Special types for fence/csr instructions
    FENCE,
    FENCEI,
    CSR_T,
    CSRI_T,

    SHIFTI,

    R_TYPE,
    I_TYPE,
    S_TYPE,
    B_TYPE,
    U_TYPE,
    J_TYPE
} InstType;

typedef enum {
    NONE, RD, RS1, RS2, IMM, OFFS, PRED, SUCC, CSR
} InstTok;

typedef InstTok InstTokList [0:3];

typedef struct {
    InstType inst_type;
    logic [6:0] opcode;
    logic [2:0] fn3;
    logic [6:0] fn7;
} InstDefn;

/* A case statement is used instead of an associative
 * array to allow functions using this to be
 * 'constant functions'
 */
function InstDefn inst_table(input string i);
  case (i)
  "lui"    : return '{U_TYPE, 7'b0110111, 3'b  x, 7'b      x};
  "auipc"  : return '{U_TYPE, 7'b0010111, 3'b  x, 7'b      x};
  "jal"    : return '{J_TYPE, 7'b1101111, 3'b  x, 7'b      x};
  "jalr"   : return '{I_TYPE, 7'b1100111, 3'b000, 7'b      x};
  "beq"    : return '{B_TYPE, 7'b1100011, 3'b000, 7'b      x};
  "bne"    : return '{B_TYPE, 7'b1100011, 3'b001, 7'b      x};
  "blt"    : return '{B_TYPE, 7'b1100011, 3'b100, 7'b      x};
  "bge"    : return '{B_TYPE, 7'b1100011, 3'b101, 7'b      x};
  "bltu"   : return '{B_TYPE, 7'b1100011, 3'b110, 7'b      x};
  "bgeu"   : return '{B_TYPE, 7'b1100011, 3'b111, 7'b      x};
  "lb"     : return '{L_TYPE, 7'b0000011, 3'b000, 7'b      x};
  "lh"     : return '{L_TYPE, 7'b0000011, 3'b001, 7'b      x};
  "lw"     : return '{L_TYPE, 7'b0000011, 3'b010, 7'b      x};
  "lbu"    : return '{L_TYPE, 7'b0000011, 3'b100, 7'b      x};
  "lhu"    : return '{L_TYPE, 7'b0000011, 3'b101, 7'b      x};
  "sb"     : return '{S_TYPE, 7'b0100011, 3'b000, 7'b      x};
  "sh"     : return '{S_TYPE, 7'b0100011, 3'b001, 7'b      x};
  "sw"     : return '{S_TYPE, 7'b0100011, 3'b010, 7'b      x};
  "addi"   : return '{I_TYPE, 7'b0010011, 3'b000, 7'b      x};
  "slti"   : return '{I_TYPE, 7'b0010011, 3'b010, 7'b      x};
  "sltiu"  : return '{I_TYPE, 7'b0010011, 3'b011, 7'b      x};
  "xori"   : return '{I_TYPE, 7'b0010011, 3'b100, 7'b      x};
  "ori"    : return '{I_TYPE, 7'b0010011, 3'b110, 7'b      x};
  "andi"   : return '{I_TYPE, 7'b0010011, 3'b111, 7'b      x};
  "slli"   : return '{SHIFTI, 7'b0010011, 3'b001, 7'b0000000};
  "srli"   : return '{SHIFTI, 7'b0010011, 3'b101, 7'b0000000};
  "srai"   : return '{SHIFTI, 7'b0010011, 3'b101, 7'b0100000};
  "add"    : return '{R_TYPE, 7'b0110011, 3'b000, 7'b0000000};
  "sub"    : return '{R_TYPE, 7'b0110011, 3'b000, 7'b0100000};
  "sll"    : return '{R_TYPE, 7'b0110011, 3'b001, 7'b0000000};
  "slt"    : return '{R_TYPE, 7'b0110011, 3'b010, 7'b0000000};
  "sltu"   : return '{R_TYPE, 7'b0110011, 3'b011, 7'b0000000};
  "xor"    : return '{R_TYPE, 7'b0110011, 3'b100, 7'b0000000};
  "srl"    : return '{R_TYPE, 7'b0110011, 3'b101, 7'b0000000};
  "sra"    : return '{R_TYPE, 7'b0110011, 3'b101, 7'b0100000};
  "or"     : return '{R_TYPE, 7'b0110011, 3'b110, 7'b0000000};
  "and"    : return '{R_TYPE, 7'b0110011, 3'b111, 7'b0000000};
  "fence"  : return '{FENCE,  7'b0001111, 3'b000, 7'b      x};
  "fencei" : return '{FENCEI, 7'b0001111, 3'b001, 7'b      x};
  "csrrw"  : return '{CSR_T,  7'b1110011, 3'b001, 7'b      x};
  "csrrs"  : return '{CSR_T,  7'b1110011, 3'b010, 7'b      x};
  "csrrc"  : return '{CSR_T,  7'b1110011, 3'b011, 7'b      x};
  "csrrwi" : return '{CSRI_T, 7'b1110011, 3'b101, 7'b      x};
  "csrrsi" : return '{CSRI_T, 7'b1110011, 3'b110, 7'b      x};
  "csrrci" : return '{CSRI_T, 7'b1110011, 3'b111, 7'b      x};
  endcase
endfunction

function logic [4:0] regs(string i);
  case (i)
  "x0","zero"     : return  0;
  "x1","ra"       : return  1;
  "x2","sp"       : return  2;
  "x3","gp"       : return  3;
  "x4","tp"       : return  4;
  "x5","t0"       : return  5;
  "x6","t1"       : return  6;
  "x7","t2"       : return  7;
  "x8","s0","fp"  : return  8;
  "x9","s1"       : return  9;
  "x10","a0"      : return 10;
  "x11","a1"      : return 11;
  "x12","a2"      : return 12;
  "x13","a3"      : return 13;
  "x14","a4"      : return 14;
  "x15","a5"      : return 15;
  "x16","a6"      : return 16;
  "x17","a7"      : return 17;
  "x18","s2"      : return 18;
  "x19","s3"      : return 19;
  "x20","s4"      : return 20;
  "x21","s5"      : return 21;
  "x22","s6"      : return 22;
  "x23","s7"      : return 23;
  "x24","s8"      : return 24;
  "x25","s9"      : return 25;
  "x26","s10"     : return 26;
  "x27","s11"     : return 27;
  "x28","t3"      : return 28;
  "x29","t4"      : return 29;
  "x30","t5"      : return 30;
  "x31","t6"      : return 31;
  default         : return 'bx;
  endcase
endfunction

bit [11:0] csr_addrs[string] = '{
    "mvendorid" : 'hf11,
    "marchid"   : 'hf12,
    "mimpid"    : 'hf13,
    "mhartid"   : 'hf14,
    "mstatus"   : 'h300,
    "misa"      : 'h301,
    "mie"       : 'h304,
    "mtvec"     : 'h305,
    "mscratch"  : 'h340,
    "mepc"      : 'h341,
    "mcause"    : 'h342,
    "mtval"     : 'h343,
    "mip"       : 'h344
};

function InstTokList inst_fmt(InstType t);
  case (t)
  L_TYPE: return '{RD,   OFFS, RS1,  NONE};
  R_TYPE: return '{RD,   RS1,  RS2,  NONE};
  I_TYPE: return '{RD,   RS1,  IMM,  NONE};
  S_TYPE: return '{RS2,  OFFS, RS1,  NONE};
  B_TYPE: return '{RS1,  RS2,  IMM,  NONE};
  U_TYPE: return '{RD,   IMM,  NONE, NONE};
  J_TYPE: return '{RD,   IMM,  NONE, NONE};
  FENCE:  return '{PRED, SUCC, NONE, NONE};
  FENCEI: return '{NONE, NONE, NONE, NONE};
  CSR_T:  return '{RD,   RS1,  CSR,  NONE};
  CSRI_T: return '{RD,   IMM,  CSR,  NONE};
  SHIFTI: return '{RD,   RS1,  IMM,  NONE};
  endcase
endfunction

function bit isspace(byte c);
    return c == " " || c == "\t";
endfunction

/* Compile a line of assembly
 */
function logic [31:0] I(string s);
    InstDefn def;
    InstTokList tl;
    string tok;
    string op, rd, rs1, rs2, csr;
    integer imm, pred, succ;
    int i, j, t;

    i = 0;
    while (isspace(s[i])) ++i;
    for (j = i+1; !isspace(s[j]); ++j);

    op  = s.substr(i, j-1);
    def = inst_table(op);
    tl  = inst_fmt(def.inst_type);

    for (i = j, t = 0; i < s.len && tl[t] != NONE; ++i) begin
        while(isspace(s[i])) ++i;

        for (j = i + 1; j <= s.len; ++j) begin
            if (isspace(s[j])
                || s[j] == "," || s[j] == "(" || s[j] == ")"
                || j == s.len) begin

                tok = s.substr(i, j - 1);
                case (tl[t])
                    RD:   rd   = tok;
                    RS1:  rs1  = tok;
                    RS2:  rs2  = tok;
                    IMM:  imm  = tok.atoi();
                    OFFS: imm  = tok.atoi();
                    PRED: pred = tok.atoi();
                    SUCC: succ = tok.atoi();
                    CSR:  csr  = tok;
                endcase

                if (tl[t] == OFFS)
                    while (s[j] != "(") ++j;
                else
                    while (j < s.len && s[j] != ",") ++j;

                ++t;
                i = j;
                break;
            end
        end
    end

    //const static logic [31:0] inst_val[InstType] = '{
    case (def.inst_type)
    R_TYPE: return {def.fn7, regs(rs2), regs(rs1), def.fn3,
        regs(rd), def.opcode};
    I_TYPE: return {imm[11:0], regs(rs1), def.fn3, regs(rd), def.opcode};
    L_TYPE: return {imm[11:0], regs(rs1), def.fn3, regs(rd), def.opcode};
    S_TYPE: return {imm[11:5], regs(rs2), regs(rs1), def.fn3,
        imm[4:0], def.opcode};
    B_TYPE: return {imm[12], imm[10:5], regs(rs2), regs(rs1),
        def.fn3, imm[4:1], imm[11], def.opcode};
    U_TYPE: return {imm[19:0], regs(rd), def.opcode};
    J_TYPE: return {imm[20], imm[10:1], imm[11], imm[19:12],
        regs(rd), def.opcode};
    FENCE:  return {4'b0, pred[3:0], succ[3:0], 13'b0, def.opcode};
    FENCEI: return {17'b0, 3'b001, 5'b0, def.opcode};
    CSR_T:  return {csr_addrs[csr], regs(rs1), def.fn3, regs(rd), def.opcode};
    CSRI_T: return {csr_addrs[csr], imm[4:0], def.fn3, regs(rd), def.opcode};
    SHIFTI: return {def.fn7, imm[4:0], regs(rs1), def.fn3,
        regs(rd), def.opcode};
    endcase
endfunction
