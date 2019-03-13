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

    // Special types for fence instructions
    FENCE,
    FENCEI,

    R_TYPE,
    I_TYPE,
    S_TYPE,
    B_TYPE,
    U_TYPE,
    J_TYPE
} InstType;

typedef enum {
    NONE, RD, RS1, RS2, IMM, OFFS, PRED, SUCC
} InstTok;

typedef InstTok InstTokList [0:3];

typedef struct {
    InstType inst_type;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
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
  "slli"   : return '{I_TYPE, 7'b0010011, 3'b001, 7'b0000000};
  "srli"   : return '{I_TYPE, 7'b0010011, 3'b101, 7'b0000000};
  "srai"   : return '{I_TYPE, 7'b0010011, 3'b101, 7'b0100000};
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
  endcase
endfunction

function logic [4:0] reg_bits(string i);
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
  endcase
endfunction

function [6:0] _opcode(input string i);
    return inst_table(i).opcode;
endfunction

function [2:0] _funct3(input string i);
    return inst_table(i).funct3;
endfunction

function [6:0] _funct7(input string i);
    return inst_table(i).funct7;
endfunction

/* The callX functions return an instruction with the
 * X-type instruction format.
 */
function logic [31:0] callr(string i, string rd, rs1, rs2);
    return {_funct7(i), reg_bits(rs2), reg_bits(rs1),
            _funct3(i), reg_bits(rd), _opcode(i)};
endfunction

function logic [31:0] calli(string i, string rd, rs1, input [11:0] imm);
    case (i)
    "slli","srli","srai":
        return {_funct7(i), imm[$clog2(`XLEN)-1:0],
                reg_bits(rs1), _funct3(i), reg_bits(rd), _opcode(i)};
    default:
        return {imm, reg_bits(rs1), _funct3(i), reg_bits(rd), _opcode(i)};
    endcase
endfunction

function logic [31:0] calls(string i, string rs2, rs1, logic [11:0] imm);
    return {imm[11:5], reg_bits(rs2), reg_bits(rs1),
            _funct3(i), imm[4:0], _opcode(i)};
endfunction

function logic [31:0] callb(string i, string rs1, rs2, input [12:0] imm);
    return {imm[12], imm[10:5], reg_bits(rs2), reg_bits(rs1),
            _funct3(i), imm[4:1], imm[11], _opcode(i)};
endfunction

function logic [31:0] callu(string i, string rd, logic [31:12] imm);
    return {imm, reg_bits(rd), _opcode(i)};
endfunction

function logic [31:0] callj(string i, string rd, input [20:0] imm);
    return {imm[20], imm[10:1], imm[11], imm[19:12], reg_bits(rd), _opcode(i)};
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
    string op, rd, rs1, rs2;
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

    case (def.inst_type)
        R_TYPE: return callr(op, rd, rs1, rs2);
        I_TYPE: return calli(op, rd, rs1, imm);
        L_TYPE: return calli(op, rd, rs1, imm);
        S_TYPE: return calls(op, rs2, rs1, imm);
        B_TYPE: return callb(op, rs1, rs2, imm);
        U_TYPE: return callu(op, rd, imm);
        J_TYPE: return callj(op, rd, imm);
        FENCE:  return calli(op, "x0", "x0", {4'b0, pred[3:0], succ[3:0]});
        FENCEI: return calli(op, "x0", "x0", 0);
    endcase
endfunction
