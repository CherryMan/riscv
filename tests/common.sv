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

`define CLK_INIT(clk) clk = 1
`define CYCLE_CLK #(`CLK_PERIOD * 1ns)
`define CYCLE_HALF #(`CLK_PERIOD/2 * 1ns)
