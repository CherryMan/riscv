`define CLK_PERIOD 20
`define CLK_CREATE(clk)         \
    always begin                \
        #(`CLK_PERIOD/2 * 1ns); \
        clk <= ~clk;            \
    end

`define CLK_INIT(clk) clk <= 0
`define CYCLE_CLK #(`CLK_PERIOD * 1ns)
