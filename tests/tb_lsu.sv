`include "vunit_defines.svh"
`include "common.sv"
`include "lsu.v"

module tb_LSU;
    localparam XLEN = `XLEN;

    integer n;

    logic is_load, is_store;
    logic [2:0] fn3;
    logic [XLEN-1:0] mem_dout;

    wire mem_r;
    wire [XLEN/8-1:0] mem_w;
    wire [XLEN-1:0] load_data;

    LSU #(XLEN) lsu (.*);

    `TEST_SUITE begin
        `TEST_CASE_SETUP begin
            is_load  = 0;
            is_store = 0;
        end

        `TEST_CASE("store widths") begin
            is_store = 0;
            fn3 = 3'b000; #1ns `CHECK_EQUAL(mem_w, 4'b0000);
            fn3 = 3'b001; #1ns `CHECK_EQUAL(mem_w, 4'b0000);
            fn3 = 3'b010; #1ns `CHECK_EQUAL(mem_w, 4'b0000);

            is_store = 1;
            fn3 = 3'b000; #1ns `CHECK_EQUAL(mem_w, 4'b0001);
            fn3 = 3'b001; #1ns `CHECK_EQUAL(mem_w, 4'b0011);
            fn3 = 3'b010; #1ns `CHECK_EQUAL(mem_w, 4'b1111);
        end

        `TEST_CASE("load bit set") begin
            is_load = 0;
            #1ns `CHECK_EQUAL(mem_r, 0);

            is_load = 1;
            #1ns `CHECK_EQUAL(mem_r, 1);
        end

        `TEST_CASE("load data widths") begin
            n = $urandom();
            #1ns
            mem_dout = n;

            /* LB  */ fn3 = 3'b000; #1ns `CHECK_EQUAL(load_data, {{XLEN- 8{1'b1}}, n[ 7:0]});
            /* LH  */ fn3 = 3'b001; #1ns `CHECK_EQUAL(load_data, {{XLEN-16{1'b1}}, n[15:0]});
            /* LW  */ fn3 = 3'b010; #1ns `CHECK_EQUAL(load_data, {{XLEN-32{1'b1}}, n[31:0]});

            /* LBU */ fn3 = 3'b100; #1ns `CHECK_EQUAL(load_data, {{XLEN- 8{1'b0}}, n[ 7:0]});
            /* LHU */ fn3 = 3'b101; #1ns `CHECK_EQUAL(load_data, {{XLEN-16{1'b0}}, n[15:0]});
        end
    end
endmodule
