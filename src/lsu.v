/* Load/Store Unit
 */
module LSU
 #( parameter XLEN = 32
  , parameter MAX_BYTES = XLEN / 8
 )( input is_load, is_store
  , input [2:0] fn3
  , input [XLEN-1:0] mem_dout
  , output mem_r
  , output reg [MAX_BYTES-1:0] mem_w
  , output reg [XLEN-1:0] load_data
 );

    assign mem_r = is_load;

    always @* begin
        if (is_store)
            case (fn3)
            3'b000:  /* SB */ mem_w = 'b1;
            3'b001:  /* SH */ mem_w = 'b11;
            3'b010:  /* SW */ mem_w = 'b1111;
            default:          mem_w = 'b0;
            endcase
        else
            mem_w = 'b0;
    end

    always @* begin
        case (fn3)
        3'b000:/*LB */load_data = {{XLEN- 8{mem_dout[7]}}, mem_dout[7:0]};
        3'b001:/*LH */load_data = {{XLEN-16{mem_dout[15]}},mem_dout[15:0]};
        3'b010:/*LW */load_data = {{XLEN-32{mem_dout[31]}},mem_dout[31:0]};
        3'b100:/*LBU*/load_data = {{XLEN- 8{1'b0}}, mem_dout[7:0]};
        3'b101:/*LHU*/load_data = {{XLEN-16{1'b0}}, mem_dout[15:0]};
        default: ;
        endcase
    end
endmodule
