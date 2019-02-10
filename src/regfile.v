module RegFile
 #( parameter XLEN = 32
 )( input clk, rd_w
  , input [4:0] rd, rs1, rs2
  , input [XLEN-1:0] rd_in
  , output [XLEN-1:0] rs1_out, rs2_out
 );

    reg  [XLEN-1:0] reg_file [31:1];
    wire [XLEN-1:0] reg_data [31:0];

    assign reg_data[0] = {XLEN{1'b0}};

    generate
        genvar i;
        for (i = 1; i < 32; i = i+1)
            assign reg_data[i] = reg_file[i];
    endgenerate

    assign rs1_out = reg_data[rs1];
    assign rs2_out = reg_data[rs2];

    // Assign to reg_file iff rd_w and rd != 0
    always @(posedge clk) begin
        if (rd_w & |rd)
            reg_file[rd] <= rd_in;
    end
endmodule
