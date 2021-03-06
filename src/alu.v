module ALU
 #( parameter XLEN = 32
 )( input      [XLEN-1:0] s1
  , input      [XLEN-1:0] s2
  , input      [2:0]      op
  , input                 sub
  , input                 sra
  , output reg [XLEN-1:0] out
  , output                eq, lt, ltu
  );

    assign eq  = s1 == s2;
    assign lt  = $signed(s1) < $signed(s2);
    assign ltu = s1 < s2;

    localparam MAX_SHIFT = $clog2(XLEN);
    wire [MAX_SHIFT-1:0] shamt = s2[MAX_SHIFT-1:0];

    wire [XLEN-1:0] neg_s2 = {{XLEN{sub}}^s2} + { {(XLEN-1){1'b0}}, sub};

    always @* begin
        case (op)
          3'b000: /* ADD */ out = s1 + neg_s2;
          3'b001: /* SLL */ out = s1 << shamt;
          3'b101: /* SR  */ out = sra ? s1 >>> shamt : s1 >> shamt;
          3'b010: /* SLT */ out = {{XLEN-1{1'b0}}, lt};
          3'b011: /* SLTU */out = {{XLEN-1{1'b0}}, ltu};
          3'b100: /* XOR */ out = s1 ^ s2;
          3'b110: /* OR  */ out = s1 | s2;
          3'b111: /* AND */ out = s1 & s2;
        endcase
    end
endmodule
