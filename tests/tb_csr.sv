`include "vunit_defines.svh"
`include "common.sv"
`include "asm.sv"

`include "csr.v"

module tb_CSRs;
    localparam XLEN = `XLEN;

    logic            clk, rstl;
    logic            csr_w;
    logic [11:0]     csr_addr;
    logic [XLEN-1:0] csr_din, csr_dout;

    logic            exc_ecall, exc_break, is_mret;
    logic            trap_pc;
    logic [XLEN-1:0] pc_now, pc_trap;

    bit [XLEN-1:0]   n;

    `CLK_CREATE(clk);

    CSRs #(XLEN) csrs
      (.*);

    // Struct defining how reading and writing to CSRs
    // should behave. mask defines bits that MUST be zero,
    // and set defines bits that MUST be one. The mask is
    // applied using ((n & mask) | set).
    //
    // Cases not listed here are handled specially.
    struct {
        bit [XLEN-1:0] mask, set;
    } csr_masks [string] = '{
      "mvendorid" :'{'0, '0},
      "marchid"   :'{'0, '0},
      "mimpid"    :'{'0, '0},
      "mhartid"   :'{'0, '0},
      "mstatus"   :'{{28'b0, 1'b1, 3'b0}, { 19'b0, 2'b11, 11'b0}},
      "misa"      :'{'0, { 2'b1, {(XLEN-3-25){1'b0}}, 17'b0, 1'b1, 8'b0}},
      "mie"       :'{{ {XLEN-1-12{1'b0}}, 1'b1, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0}, '0},
      "mtvec"     :'{'0, '0}, // special case
      "mscratch"  :'{'1, '0},
      "mepc"      :'{(~1'b1), '0},
      "mcause"    :'{'0, '0}, // special case
      "mtval"     :'{'1, '0},
      "mip"       :'{{ {XLEN-1-12{1'b0}}, 1'b1, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0}, '0}
    };

    `TEST_SUITE begin
        `TEST_CASE_SETUP begin
            exc_ecall = 0;
            exc_break = 0;
            is_mret   = 0;

            csr_w = 0;
            rstl = 0;
            #1 rstl = 1;
            #1 `CLK_INIT(clk);
        end

        `TEST_CASE("reset behaviour") begin
            rstl = 0;
            #1 rstl = 1;

            csr_addr = csr_addrs["mcause"];
            #1 `CHECK_EQUAL(csr_dout, 0);

            // Only MPP == 11, MIE is cleared
            csr_addr = csr_addrs["mstatus"];
            #1 `CHECK_EQUAL(csr_dout, {19'b0, 2'b11, 11'b0});
        end

        `TEST_CASE("csr read/write behaviour") begin
            foreach (csr_masks[a]) begin
                repeat (10000) begin // fuzz
                    n = $random();
                    csr_addr = csr_addrs[a];
                    csr_din  = n;
                    csr_w = 1;
                    `CYCLE_CLK; // cycle clk to write values to csrs
                    csr_w = 0;

                    // Handle specific cases of CSR behaviour.
                    case (a)
                    "mtvec": if (n[1:0] >= 2) n[1:0] = 0;
                    "mcause": begin
                        // Ensure mcause is not one of the accepted values.
                        // If it isn't, skip because the value is invalid.
                        if (n[XLEN-1]) // if interrupt
                            case (n[XLEN-2:0])
                                2,6,10: continue;
                                default: if (n[XLEN-2:0] >= 12) continue;
                            endcase
                        else if (!n[XLEN-1]) // if exception
                            case (n[XLEN-2:0])
                                10,14,16: continue;
                                default: if (n[XLEN-2:0] >= 16) continue;
                            endcase
                    end

                    // If not a specific case, just apply the masks and
                    // set necessary bits to one.
                    default: begin
                        n = (n & csr_masks[a].mask) | csr_masks[a].set;
                    end
                    endcase

                    #1 `CHECK_EQUAL(csr_dout, n,
                        $sformatf("CSR: %s at 0x%h", a, csr_addrs[a]));

                    // Reset the CSR every time to avoid effects from
                    // CSR state.
                    rstl = 0;
                    #1 rstl = 1;
                    #1 `CLK_INIT(clk);
                end
            end
        end

        `TEST_CASE("trap execution and return") begin
            n = $random & ~1; // set LSB to 0
            pc_now = $random;

            csr_addr = csr_addrs["mtvec"];
            csr_din  = n & ~1;
            csr_w    = 1;
            `CYCLE_CLK;

            csr_w = 0;
            exc_ecall = 1;
            #1 `CHECK_EQUAL(trap_pc, 1);
               `CHECK_EQUAL(pc_trap, n);

            exc_ecall = 0;
            exc_break = 1;
            #1 `CHECK_EQUAL(trap_pc, 1);
               `CHECK_EQUAL(pc_trap, n);

            `CYCLE_CLK; // trigger trap
            exc_break = 0;
            csr_addr = csr_addrs["mepc"];
            #1 `CHECK_EQUAL(csr_dout, pc_now);

            is_mret = 1;
            #1 `CHECK_EQUAL(pc_trap, pc_now + 4);
        end
    end
endmodule
