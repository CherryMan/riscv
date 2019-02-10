`ifndef XLEN
`define XLEN 32
`endif

/* Macros for creating and managing
 * a clock.
 */
`define CLK_PERIOD 20
`define CLK_CREATE(clk)         \
    always begin                \
        #(`CLK_PERIOD/2 * 1ns); \
        clk <= ~clk;            \
    end

`define CLK_INIT(clk) clk <= 0
`define CYCLE_CLK #(`CLK_PERIOD * 1ns)


/* Several functions used to return the bits of an
 * instruction. Used to create instruction bit values
 * for testing.
 */

/* opcode = _dec_inst[6:0]
 * funct3 = _dec_inst[9:7]
 * funct7 = _dec_inst[16:10]
 */
function [16:0] _dec_inst(input string i);
    begin
    case (i)        /*funct7       funct3  opcode    */
    "lui"   : return {7'b      x, 3'b  x, 7'b0110111};
    "auipc" : return {7'b      x, 3'b  x, 7'b0010111};
    "jal"   : return {7'b      x, 3'b  x, 7'b1101111};
    "jalr"  : return {7'b      x, 3'b000, 7'b1100111};
    "beq"   : return {7'b      x, 3'b000, 7'b1100011};
    "bne"   : return {7'b      x, 3'b001, 7'b1100011};
    "blt"   : return {7'b      x, 3'b100, 7'b1100011};
    "bge"   : return {7'b      x, 3'b101, 7'b1100011};
    "bltu"  : return {7'b      x, 3'b110, 7'b1100011};
    "bgeu"  : return {7'b      x, 3'b111, 7'b1100011};
    "lb"    : return {7'b      x, 3'b000, 7'b0000011};
    "lh"    : return {7'b      x, 3'b001, 7'b0000011};
    "lw"    : return {7'b      x, 3'b010, 7'b0000011};
    "lbu"   : return {7'b      x, 3'b100, 7'b0000011};
    "lhu"   : return {7'b      x, 3'b101, 7'b0000011};

    "sb"    : return {7'b      x, 3'b000, 7'b0100011};
    "sh"    : return {7'b      x, 3'b001, 7'b0100011};
    "sw"    : return {7'b      x, 3'b010, 7'b0100011};

    "addi"  : return {7'b      x, 3'b000, 7'b0010011};
    "slti"  : return {7'b      x, 3'b010, 7'b0010011};
    "sltiu" : return {7'b      x, 3'b011, 7'b0010011};
    "xori"  : return {7'b      x, 3'b100, 7'b0010011};
    "ori"   : return {7'b      x, 3'b110, 7'b0010011};
    "andi"  : return {7'b      x, 3'b111, 7'b0010011};
    "slli"  : return {7'b0000000, 3'b001, 7'b0010011};
    "srli"  : return {7'b0000000, 3'b101, 7'b0010011};
    "srai"  : return {7'b0100000, 3'b101, 7'b0010011};

    "add"   : return {7'b0000000, 3'b000, 7'b0110011};
    "sub"   : return {7'b0100000, 3'b000, 7'b0110011};
    "sll"   : return {7'b0000000, 3'b001, 7'b0110011};
    "slt"   : return {7'b0000000, 3'b010, 7'b0110011};
    "sltu"  : return {7'b0000000, 3'b011, 7'b0110011};
    "xor"   : return {7'b0000000, 3'b100, 7'b0110011};
    "srl"   : return {7'b0000000, 3'b101, 7'b0110011};
    "sra"   : return {7'b0100000, 3'b101, 7'b0110011};
    "or"    : return {7'b0000000, 3'b110, 7'b0110011};
    "and"   : return {7'b0000000, 3'b111, 7'b0110011};

    //"" : return {7'b      x, 3'b000, 7'b0000011};
    endcase
    end
endfunction

function [6:0] _opcode(input string i);
    return _dec_inst(i)[6:0];
endfunction

function [2:0] _funct3(input string i);
    return _dec_inst(i)[9:7];
endfunction

function [6:0] _funct7(input string i);
    return _dec_inst(i)[16:10];
endfunction

/* The callX functions return an instruction with the
 * X-type instruction format.
 */
function logic [`XLEN-1:0] callr(string i, input [4:0] rd, rs1, rs2);
    return {_funct7(i), rs2, rs1, _funct3(i), rd, _opcode(i)};
endfunction

function logic [`XLEN-1:0] calli
    (string i, input [4:0] rd, rs1, input [11:0] imm);

    case (i)
    "slli","srli","srai":
        return {_funct7(i), imm[$clog2(`XLEN)-1:0],
                rs1, _funct3(i), rd, _opcode(i)};
    default:
        return {imm, rs1, _funct3(i), rd, _opcode(i)};
    endcase
endfunction

function logic [`XLEN-1:0] calls
    (string i, input [4:0] rs1, rs2, input [11:0] imm);
    return {imm[11:5], rs2, rs1, _funct3(i), imm[4:0], _opcode(i)};
endfunction

function logic [`XLEN-1:0] callb
    (string i, input [4:0] rs1, rs2, input [12:1] imm);
    return {imm[12], imm[10:5], rs2, rs1,
        _funct3(i), imm[4:1], imm[11], _opcode(i)};
endfunction

function logic [`XLEN-1:0] callu(string i, input [4:0] rd, input [31:12] imm);
    return {imm, rd, _opcode(i)};
endfunction

function logic [`XLEN-1:0] callj(string i, input [4:0] rd, input [20:1] imm);
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, _opcode(i)};
endfunction
