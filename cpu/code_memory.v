module code_memory ( input [31:0] pc_i, output [31:0] inst );
  wire [7:0] code_memory [0:67];

  initial begin
    { code_memory[0], code_memory[1], code_memory[2], code_memory[3] } <= 32'b0000_000_0100_1_0010_0000_00000_00_0_0001; // add r0, r1, r2
    { code_memory[4], code_memory[5], code_memory[6], code_memory[7] } <= 32'b0000_000_0000_1_0010_0100_00000_00_0_0001; // and r4, r1, r2
    { code_memory[8], code_memory[9], code_memory[10], code_memory[11] } <= 32'b0000_000_0001_1_0010_0100_00000_00_0_0001; // xor r4, r1, r2
    { code_memory[12], code_memory[13], code_memory[14], code_memory[15] } <= 32'b0000_000_0010_1_0010_0100_00000_00_0_0001; // sub r4, r1, r2
    { code_memory[16], code_memory[17], code_memory[18], code_memory[19] } <= 32'b0000_000_0100_1_0010_0100_00000_00_0_0001; // add r4, r1, r2
    { code_memory[20], code_memory[21], code_memory[22], code_memory[23] } <= 32'b0000_000_1000_1_0010_0100_00000_00_0_0001; // test r4, r1, r2
    { code_memory[24], code_memory[25], code_memory[26], code_memory[27] } <= 32'b0000_000_1001_1_0010_0100_00000_00_0_0001; // testeq r4, r1, r2
    { code_memory[28], code_memory[29], code_memory[30], code_memory[31] } <= 32'b0000_000_1010_1_0010_0100_00000_00_0_0001; // compare r4, r1, r2
    { code_memory[32], code_memory[33], code_memory[34], code_memory[35] } <= 32'b0000_000_1100_1_0010_0100_00000_00_0_0001; // orr r4, r1, r2
    { code_memory[36], code_memory[37], code_memory[38], code_memory[39] } <= 32'b0000_000_1101_1_0010_0100_00000_00_0_0001; // mov r4, r1, r2
    { code_memory[40], code_memory[41], code_memory[42], code_memory[43] } <= 32'b0000_000_1110_1_0010_0100_00000_00_0_0001; // bit clear r4, r1, r2
    { code_memory[44], code_memory[45], code_memory[46], code_memory[47] } <= 32'b0000_000_1111_1_0010_0100_00000_00_0_0001; // mov not r4, r1, r2
    { code_memory[48], code_memory[49], code_memory[50], code_memory[51] } <= 32'b0000_001_0010_1_0111_0011_0000_00000001; // sub r3, r7, #1
    { code_memory[52], code_memory[53], code_memory[54], code_memory[55] } <= 32'b0000_000_0100_1_0010_0000_00000_00_0_0001; // add r0, r1, r2
    { code_memory[56], code_memory[57], code_memory[58], code_memory[59] } <= 32'b0000_101_1_00000000_00000000_00000000; // blEQ 0x4
    { code_memory[60], code_memory[61], code_memory[62], code_memory[63] } <= 32'b1110_101_1_11111111_11111111_11101111; // blAL 0x4
    { code_memory[64], code_memory[65], code_memory[66], code_memory[67] } <= 32'b0000_001_0010_0_0111_0011_0000_00000001; // sub r3, r7, #1  // Will not reach
  end

  assign inst = { code_memory[pc_i], code_memory[pc_i+1], code_memory[pc_i+2], code_memory[pc_i+3] };
endmodule
