`include "vunit_defines.svh"
`include "asm.sv"
`include "common.sv"
`include "cpu.v"

module tb_CPU;
    localparam XLEN = `XLEN;
    localparam BYTES = XLEN / 8;

    logic clk, rstn;
    logic [XLEN-1:0] mem_dout, rom_data;

    wire mem_r;
    wire [XLEN/8-1:0] mem_w;
    wire [XLEN-1:0] mem_din;
    wire [XLEN-1:0] rom_addr, mem_addr;

    integer n; // tmp var used in some tests

    CPU #(XLEN) cpu (.*);

    `CLK_CREATE(clk);

    // Memory and ROM for CPU
    logic [7:0] mem [logic [XLEN-1:0]];
    logic [31:0] rom [];

    // Memory read logic
    always @* begin
        if (mem_r)
            for (int i = 0; i < BYTES; ++i)
                mem_dout[i*8 +: 8] = mem.exists(mem_addr+i) ?
                    mem[mem_addr + i] : 'bx;
        else
            mem_dout = 'bx;
    end

    // Memory write logic
    always @(negedge clk) begin
        for (int i = 0; i < BYTES; ++i)
            if (mem_w[i])
                mem[mem_addr + i] = mem_din[i*8 +: 8];
    end

    // ROM read logic
    // The ROM addrs are multiples of 4, but
    // the ROM here is stored as an array of
    // WORDS. Thus, the address is divided by 4.
    always @* begin
        rom_data = rom[rom_addr / 4];
    end

    task print_mem;
        logic [XLEN-1:0] i;
        if (mem.first(i))
            do
                $display("mem[%4d]: %d", i, mem[i]);
            while (mem.next(i));
    endtask

    task run();
        rstn = 1;
        #1 rstn = 0;
        #1 `CLK_INIT(clk);

        // TODO: Detect end based on syscall? There must be a better way
        while (rom_addr <= 4*rom.size()) `CYCLE_CLK;

        // Output is printed on failure, so printing
        // memory every time is useful in case of failure.
        print_mem();
    endtask

    task assert_mem(logic [XLEN-1:0] addr, integer len, val);
        for (integer i = 0; i < len; ++i)
            `CHECK_EQUAL(mem[addr+i], val[i*8 +: 8],
                         $sformatf("mem[%4d] != %d", addr+i, val[i*8 +: 8]));
    endtask

    `define assert_mem_b(a, v) assert_mem(a, 1, v)
    `define assert_mem_h(a, v) assert_mem(a, 2, v)
    `define assert_mem_w(a, v) assert_mem(a, 4, v)

    `TEST_SUITE begin
        `TEST_CASE("basic load and store") begin
            rom = '{
                I("addi x1, x0, 123"),
                I("sb x1, 0(x0)"),
                I("lb x2, 0(x0)"),
                I("addi x2, x2, 100"),
                I("sb x2, 1(x0)"),

                I("addi x4, x0, 321"),
                I("addi x5, x0, 8"),
                I("sw   x4, 4(x5)")
            };
            run();

            `assert_mem_b(0,  123);
            `assert_mem_b(1,  223);
            `assert_mem_w(12, 321);
        end

        `TEST_CASE("arithmetic operations") begin
            rom = '{
                I("addi  x1, x0, 100"), // x1  = 100
                I("slti  x2, x1, 120"), // x2  = 1
                I("sltiu x3, x1, 120"), // x3  = 1
                I("xori  x4, x1, 1"),   // x4  = 101
                I("ori   x5, x1, 27"),  // x5  = 127
                I("andi  x6, x1, 28"),  // x6  = 4
                I("slli  x7, x1, 2"),   // x7  = 400
                I("srli  x8, x1, 2"),   // x8  = 25
                I("srai  x9, x1, 2"),   // x9  = 25

                I("add  x10, x1, x4"),  // x10 = 201
                I("sub  x11, x1, x4"),  // x11 = -1
                I("sll  x12, x1, x2"),  // x12 = 200
                I("slt  x13, x1, x4"),  // x13 = 1
                I("sltu x14, x1, x4"),  // x14 = 1
                I("xor  x15, x1, x4"),  // x15 = 1
                I("srl  x16, x1, x2"),  // x16 = 50
                I("sra  x17, x1, x2"),  // x17 = 50
                I("or   x18, x1, x12"), // x18 = 236
                I("and  x19, x1, x12")  // x19 = 64
            };

            n = rom.size(); // number of instructions

            rom = new[n*2](rom);
            for (integer i = 0; i < n; ++i)
                rom[n+i] = I($sformatf("sw x%0d, %d(x0)", i+1, i*4));

            run();

            `assert_mem_w(0,  100);
            `assert_mem_w(4,    1);
            `assert_mem_w(8,    1);
            `assert_mem_w(12, 101);
            `assert_mem_w(16, 127);
            `assert_mem_w(20,   4);
            `assert_mem_w(24, 400);
            `assert_mem_w(28,  25);
            `assert_mem_w(32,  25);

            `assert_mem_w(36, 201);
            `assert_mem_w(40,  -1);
            `assert_mem_w(44, 200);
            `assert_mem_w(48,   1);
            `assert_mem_w(52,   1);
            `assert_mem_w(56,   1);
            `assert_mem_w(60,  50);
            `assert_mem_w(64,  50);
            `assert_mem_w(68, 236);
            `assert_mem_w(72,  64);
        end

        `TEST_CASE("branches and jumps") begin
            rom = '{
            // load constants
            /* 00 */ I("addi x30, x0, 1"), // MILESTONE val
            /* 01 */ I("addi x1, x0, 123"),
            /* 02 */ I("addi x2, x0, 132"),
            /* 03 */ I("addi x3, x0, -10"),
            /* 04 */ I("addi x4, x0,  -1"),

            // jmp insts
            /* 05 */ I("jal x31, 12"),
            /* 06 */ I("sb x30, 0(x0)"),
            /* 07 */ I("jal x0, 8"),
            /* 08 */ I("jalr x0, x31, 0"),
            /* 09 */ I("sb x30, 1(x0)"), // MILESTONE 1

            // unsigned branch insts
            /* 10 */ I("bne x1, x2, 8"),
            /* 11 */ I("beq x1, x2, 16"),
            /* 12 */ I("addi x1, x1, 1"),
            /* 13 */ I("bltu x1, x2, -12"),
            /* 14 */ I("bgeu x1, x2, -16"),
            /* 15 */ I("sb x30, 2(x0)"), // MILESTONE 2

            // signed branch insts
            /* 16 */ I("bne x3, x4, 8"),
            /* 17 */ I("beq x3, x4, 16"),
            /* 18 */ I("addi x3, x3, 1"),
            /* 19 */ I("blt x3, x4, -12"),
            /* 20 */ I("bge x3, x4, -16"),
            /* 21 */ I("sb x30, 3(x0)") // MILESTONE 3
            };
            run();

            `assert_mem_b(0, 1);
            `assert_mem_b(1, 1);
            `assert_mem_b(2, 1);
            `assert_mem_b(3, 1);
        end
    end

    `WATCHDOG(1ms);
endmodule
