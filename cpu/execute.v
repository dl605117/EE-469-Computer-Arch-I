module execute (
    input [31:0] r1_i
  , input [31:0] r2_i
  , input [31:0] inst_i
  , input stall_i
  , output [31:0] inst_o
  , output [31:0] ALU_data_o
  , output stall_o
);
  /////////// Assign statements ///////////
  assign opcode = inst_i[21+:4];
  assign instruction_codes = inst_i[25+:3];

  ALU alu (.instruction_codes(instruction_codes),.opcode(opcode), .r2(r2), .r1(r1), .operand2(operand2), .data(ALU_data));
endmodule
