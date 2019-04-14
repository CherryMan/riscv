module CSRs
 #( parameter XLEN = 32
 )( input                 clk, rstl
  , input      [11:0]     csr_addr
  , input                 csr_w
  , input      [XLEN-1:0] csr_din
  , output reg [XLEN-1:0] csr_dout
 );

    wire [XLEN-1:0]
      mstatus
    , misa
    , mie
    , mip
    , mtvec
    , mcause
    ;
    reg [XLEN-1:0]
      mscratch
    , mepc
    , mtval
    ;

    localparam
      MSTATUS  = 'h300
    , MISA     = 'h301
    , MIE      = 'h304
    , MTVEC    = 'h305
    , MSCRATCH = 'h340
    , MEPC     = 'h341
    , MCAUSE   = 'h342
    , MTVAL    = 'h343
    , MIP      = 'h344
    ;

    // -- Setup for CSR registers

    // mstatus
    assign mstatus[2:0]       = 0;
    assign mstatus[3]         = 1;
    assign mstatus[10:4]      = 0;
    assign mstatus[12:11]     = 2'b11;
    assign mstatus[XLEN-1:13] = 0;

    // misa
    generate
        assign misa[XLEN-1:XLEN-2] = XLEN == 32  ? 1
                                   : XLEN == 64  ? 2
                                   : XLEN == 128 ? 3
                                   : 0;

        assign misa[XLEN-3:26] = 'b0; // WPRI

        // If the extension is enabled, the bit is set to 1.
        // Otherwise, it is set to 0.
        genvar i;
        for (i = 0; i < 26; i = i+1) begin
            case ("A"+i)
            "I"     : assign misa[i] = 1;
            default : assign misa[i] = 0;
            endcase
        end
    endgenerate

    // mip, mie
    localparam
      MI_MSI = 3
    , MI_MTI = 7
    , MI_MEI = 11;
    reg mie_meie, mie_mtie, mie_msie;
    reg mip_meip, mip_mtip, mip_msip;
    assign mie = {{XLEN-12{1'b0}}, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};
    assign mip = {{XLEN-12{1'b0}}, mip_meip, 3'b0, mip_mtip, 3'b0, mip_msip, 3'b0};

    // mtvec
    reg [XLEN-1:2] mtvec_base;
    reg [1:0] mtvec_mode;
    assign mtvec = {mtvec_base, mtvec_mode};

    // mcause
    reg [XLEN-2:0] mcause_code;
    reg mcause_interr;
    assign mcause = {mcause_interr, mcause_code};

    // -- CSR Read and Write logic

    // Reset
    always @* begin
        if (!rstl) begin
            mcause_interr = 0;
            mcause_code   = 0;
        end
    end

    // CSR Read logic
    always @* begin
        casez (csr_addr)
        'hF11: csr_dout = 'b0; // mvendorid
        'hF12: csr_dout = 'b0; // marchid
        'hF13: csr_dout = 'b0; // mimpid TODO
        'hF14: csr_dout = 'b0; // mhartid TODO

        MSTATUS : csr_dout = mstatus;
        MISA    : csr_dout = misa; // TODO make writable
        // NOTE: medeleg, mideleg unimplemented
        MIE     : csr_dout = mie;
        MTVEC   : csr_dout = mtvec;
        MSCRATCH: csr_dout = mscratch;
        MEPC    : csr_dout = mepc;
        MCAUSE  : csr_dout = mcause;
        MTVAL   : csr_dout = mtval;
        MIP     : csr_dout = mip;

        default: ;
        endcase
    end

    // CSR Write logic
    always @(posedge clk) begin
      if (csr_w)
        casez (csr_addr)
        MSTATUS: ;
        MISA: ;
        MTVEC: begin
            mtvec_base <= csr_din[XLEN-1:2];
            mtvec_mode <= csr_din[1:0] <= 1 ? csr_din[1:0] : 0;
        end
        MSCRATCH: mscratch <= csr_din;
        MEPC: mepc <= {csr_din[XLEN-1:1], 1'b0};
        MIE: begin
            mie_msie <= csr_din[MI_MSI];
            mie_mtie <= csr_din[MI_MTI];
            mie_meie <= csr_din[MI_MEI];
        end
        MIP: begin
            mip_msip <= csr_din[MI_MSI];
            mip_mtip <= csr_din[MI_MTI];
            mip_meip <= csr_din[MI_MEI];
        end
        MCAUSE: begin
            // Ensure exception code is valid,
            // otherwise don't write.
            // NOTE: Kinda hacky, there's probably a better way.
            if (  (csr_din[XLEN-1])  && (
                    csr_din[XLEN-2:0] != 2  &&
                    csr_din[XLEN-2:0] != 6  &&
                    csr_din[XLEN-2:0] != 10 &&
                    csr_din[XLEN-2:0] <= 11)
               || (!csr_din[XLEN-1]) && (
                    csr_din[XLEN-2:0] != 10 &&
                    csr_din[XLEN-2:0] != 14 &&
                    csr_din[XLEN-2:0] <= 15 ))
            begin
                mcause_interr <= csr_din[XLEN-1];
                mcause_code   <= csr_din[XLEN-2:0];
            end
        end
        MTVAL: mtval <= csr_din;
        default: ;
        endcase
    end
 endmodule
