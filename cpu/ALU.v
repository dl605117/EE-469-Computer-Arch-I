module ALU (
   input [2:0] instruction_codes
  ,input [3:0] opcode
  ,input [31:0] r2, r1, operand2
  ,output [32:0] data
);


always @(*) begin
  data = 0;
  if ( instruction_codes == 3'b001 )
    case( opcode ) //add instruction bits 21 to 24
      4'b0000: data = r2 & operand2;           //and
      4'b0001: data = r2 ^ operand2;           //exclusive or
      4'b0010: data = r2 - operand2;           //sub
      4'b0100: data = operand2 + r2;           //add
      4'b1000: data = r2 && operand2;          //test
      4'b1001: data = r2 ^ operand2;           //test equivalence
      4'b1010: data = r2 - operand2;           //compare
      4'b1100: data = r2 | operand2;          //or
      4'b1101: data = operand2;                //move, need to check, it says operand2 which is 12 bits long
      4'b1110: data = r2 & ~operand2;         //bit clear
      4'b1111: data = 8'hFFFFFFFF ^ operand2;   //move not
      default: data = 32'b0;                      // not sure
    endcase
  else if ( instruction_codes == 3'b000 )
    case( opcode ) //add instruction bits 21 to 24
      4'b0000: data = r2 & r1;           //and
      4'b0001: data = r2 ^ r1;           //exclusive or
      4'b0010: data = r1 - r2;           //sub
      4'b0100: data = r1 + r2;           //add
      4'b1000: data = r2 && r1;          //test
      4'b1001: data = r2 ^ r1;           //test equivalence
      4'b1010: data = r1 - r2;           //compare
      4'b1100: data = r2 | r1;          //orr
      4'b1101: data = r1;                //move, need to check, it says operand2 which is 12 bits long
      4'b1110: data = ~r2 & r1;         //bit clear
      4'b1111: data = 8'hFFFFFFFF ^ r1;   //move not
      default: data = 32'b0;                       // not sure
    endcase
  end
endmodule
