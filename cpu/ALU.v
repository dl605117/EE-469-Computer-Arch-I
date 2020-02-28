module ALU (
   input [2:0] instruction_codes
  ,input [3:0] opcode
  ,input [31:0] a, b
  ,output [32:0] data
);
// a = rn
// b = rm (muxed in as rm or operand2)
wire [31:0] b_temp;
assign b_temp = ~b;

  always @(*) begin
    case( opcode ) //add instruction bits 21 to 24
      4'b0000: data = a & b;           //and
      4'b0001: data = a ^ b;           //exclusive or
      4'b0010: data = a + b_temp + 1;           //sub
      4'b0100: data = a + b;           //add
      4'b1000: data = a && b;          //test
      4'b1001: data = a ^ b;           //test equivalence
      4'b1010: data = a + b_temp + 1;           //compare
      4'b1100: data = a | b;          //orr
      4'b1101: data = b;                //move, need to check, it says operand2 which is 12 bits long
      4'b1110: data = ~a & b;         //bit clear
      4'b1111: data = 8'hFFFFFFFF ^ b;   //move not
      default: data = 32'b0;                       // not sure
    endcase
  end
endmodule
