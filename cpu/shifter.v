module shifter (
    input [31:0] inst_i;
    input [31:0] r1_i;
    output [31:0] r1_shift_o;
)

  assign shift_imm = inst_i[11:7];
  assign shift_type = inst_i[6:5];

  always @(*) begin
    if (shift_type == 0)  //logical shift left
      r1_shift_o = r1_i << shift_imm;
    else if (shift_type == 1) //logical shift right
      r1_shift_o = r1_i >> shift_imm;
    else if (shift_type == 2) //arithmetic shift right.
      r1_shift_o = r1_i >>> shift_imm;
  end
endmodule
