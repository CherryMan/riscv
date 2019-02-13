`include "vunit_defines.svh"
`include "asm.sv"
`include "common.sv"
`include "cpu.v"

module tb_CPU;
    localparam XLEN = `XLEN;
    localparam BYTES = XLEN / 8;

    logic clk, resetn;
    logic [XLEN-1:0] mem_dout, rom_data;

    wire mem_r;
    wire [XLEN/8-1:0] mem_w;
    wire [XLEN-1:0] mem_din;
    wire [XLEN-1:0] rom_addr, mem_addr;

    CPU cpu (.*);

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

    task run();
        resetn = 1;
        #1 resetn = 0;
        #1 `CLK_INIT(clk);

        // TODO: detect end based on rom_addr
        foreach (rom[i]) `CYCLE_CLK;
    endtask

    `TEST_SUITE begin
        `TEST_CASE("basic load and store") begin
            rom = '{
                I("addi x1, x0, 132"),
                I("sb x1, 0(x0)"),
                I("lb x2, 0(x0)"),
                I("addi x2, x2, 100"),
                I("sb x2, 1(x0)")
            };

            run();

            `CHECK_EQUAL(mem[0], 132);
            `CHECK_EQUAL(mem[1], 232);
        end
    end
endmodule
