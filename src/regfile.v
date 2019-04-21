module RegFile
 #( parameter XLEN = 32
 )( input clk, rd_w
  , input [4:0] rd, rs1, rs2
  , input [XLEN-1:0] rd_in
  , output [XLEN-1:0] rs1_out, rs2_out
 );

    reg [XLEN-1:0] reg_file [31:1];

    assign rs1_out = rs1 != 0 ? reg_file[rs1] : 0;
    assign rs2_out = rs2 != 0 ? reg_file[rs2] : 0;

    // Assign to reg_file iff rd_w == 0 and rd != 0
    always @(posedge clk) begin
        if (rd_w & |rd)
            reg_file[rd] <= rd_in;
    end
endmodule
