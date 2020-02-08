module cpu(
  input wire clk,
  input wire nreset,
  output wire led,
  output wire [7:0] debug_port1,
  output wire [7:0] debug_port2,
  output wire [7:0] debug_port3,
  output wire [7:0] debug_port4,
  output wire [7:0] debug_port5,
  output wire [7:0] debug_port6,
  output wire [7:0] debug_port7
  );

  // ************************************
  // ***** TO DOS ***********
  // ************************************
  // Debug load and STORE
  // CPSR
  // write BACK
  // Double check Conditions work


  reg [31:0] inst;
  reg [31:0] pc_r, pc_n;
  wire [31:0] operand2;
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] r1_address;
  wire [3:0] r2_address;
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  reg [31:0] r1_preshift, r2;
  reg [32:0] data;
  wire do_write;
  wire s_bit; // also L bit for load and Store
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [23:0] branch_address;
  wire [31:0] r1; //post shift r1

  assign s_bit = inst[20];
  assign branch_address = inst[0+:24];
  assign rn_address = inst[16+:4];    // r2
  assign rm_address = inst[0+:4];     // r1
  assign opcode = inst[21+:4];
  assign instruction_codes = inst[25+:3];
  assign do_write = 1'b0; // for now, will not write to register_file
  assign rotate = inst[8+:4];
  assign immediate = inst[0+:8];

  code_memory cm ( pc_r, inst );
  register_file rf ( clk, r1_address, r2_address, do_write, rd_address, data[0+:32], r1_preshift, r2 );
  rotate rot ( rotate, immediate, operand2 );
  shifter shifting (inst, r1_preshift, r1);

  // ************************************
  // ***** Register File Addressing *****
  // ************************************
  assign r2_address = rn_address;
  always @(*) begin
    if ( instruction_codes == 3'b010 )
      r1_address = rm_address;
    else
      r1_address = rd_address;
  end

  // ************************************
  // ***** NORMAL OPERATIONS & BL *******
  // ************************************
  always @(*) begin
    data = 0;
    if ( instruction_codes == 3'b010)    // LOAD AND STORE
      if ( s_bit ) // also L bit for load and Store
        if ( U_bit )
          data = r2 + inst[11:0];
        else
          data = r2 - inst[11:0];
      else
        data = rd_address + inst[11:0];
    else if ( instruction_codes == 3'b101 && do_jump )    // Setting Link Address for Branch
      data = inst[24] ? pc_r + 4 : 0;
    else
      data = ALU_data;
  end

  wire [32:0] ALU_data;
  ALU alu (.instruction_codes(instruction_codes),.opcode(opcode), .r2(r2), .r1(r1), .operand2(operand2), .data(ALU_data));
  // ************************************
  // ************ FLAGS *****************
  // ************************************

  wire n_flag, v_flag, z_flag, c_flag;
  reg [3:0] update_flags;

  // UPDATING FLAGS
  always @(*) begin
    if ( update_flags[0] )
      n_flag = data[31];     // negative flag
    else
    n_flag = n_flag;

    if ( update_flags[1] )
      z_flag = (data == 0);     // zero flag
    else
      z_flag = z_flag;

    if ( update_flags[2] )
      c_flag = data[32];     // carry flag
    else
      c_flag = c_flag;

    if ( update_flags[3] )   // overflow flag
      if(instruction_codes == 3'b001)
        v_flag = (opcode == 4'b0100) ? operand2[31] & r2[31] && (!data[31]) || (!operand2[31] & !r2[31] && data[31])
              : !operand2[31] & r2[31] && (!data[31]) || (operand2[31] & !r2[31] && data[31]);
      else
        v_flag = (opcode == 4'b0100) ? r1[31] & r2[31] && (!data[31]) || (!r1[31] & !r2[31] && data[31])
              : r1[31] & !r2[31] && (!data[31]) || (!r1[31] & r2[31] && data[31]);
    else
      v_flag = v_flag;
  end

  //4'bxxxx : {n_flag, z_flag, c_flag, v_flag}
  // SETTING UPDATE FLAGS
  always @( posedge clk ) begin
    if ( pc_r == 2'b01 & s_bit & ( instruction_codes == 3'b000 | instruction_codes == 3'b001 ) ) begin
      case ( cond )
        4'b0000: update_flags <= 4'b1110;  //AND
        4'b0001: update_flags <= 4'b1110;  // XOR
        4'b0010: update_flags <= 4'b1111;  // SUB
        4'b0100: update_flags <= 4'b1111;  // ADD
        4'b1000: update_flags <= 4'b1110;  // TEST
        4'b1001: update_flags <= 4'b1110;  // TESTQ
        4'b1010: update_flags <= 4'b1111;  // COMPARE
        4'b1100: update_flags <= 4'b1110;  // OR
        4'b1101: update_flags <= 4'b1110;  // MOV
        4'b1110: update_flags <= 4'b0000;  // BIT CLEAR
        4'b1111: update_flags <= 4'b1110;  // MOVE NOT
        default: update_flags <= 4'b0000;  // EVERYTHING ELSE
      endcase
    end
    else begin
      update_flags <= 4'b0000;    // RESETTING
    end
  end

  // ************************************
  // ******* CHECKING CONDITIONS ********
  // ************************************
  // cond code
  wire [3:0] cond;
  assign cond = inst[28+:4];
  wire do_jump;

  always @(*) begin
    do_jump = 1'b0;
    case ( cond )    // Checking Condition Codes for Jump
      4'b0000: if ( z_flag ) do_jump = 1'b1;                          // EQ
              else do_jump = 1'b0;
      4'b0001: if ( ~z_flag ) do_jump = 1'b1;				                  // NE
      4'b0010: if ( c_flag ) do_jump = 1'b1;				                  // CS/HS
      4'b0011: if ( ~c_flag ) do_jump = 1'b1; 				                // CC/LO
      4'b0100: if ( n_flag ) do_jump = 1'b1; 				                  // MI
      4'b0101: if ( ~n_flag ) do_jump = 1'b1;				                  // PL
      4'b0110: if ( v_flag ) do_jump = 1'b1;				                  // VS
      4'b0111: if ( ~v_flag ) do_jump = 1'b1; 				                // VC
      4'b1000: if ( c_flag && ~z_flag ) do_jump = 1'b1; 			        // HI
      4'b1001: if ( ~c_flag && z_flag ) do_jump = 1'b1;			          // LS
      4'b1010: if ( n_flag == v_flag ) do_jump = 1'b1; 		            // GE
      4'b1011: if ( n_flag != v_flag ) do_jump = 1'b1;		            // LT
      4'b1100: if ( ~z_flag && (n_flag == v_flag) ) do_jump = 1'b1; 	// GT
      4'b1101: if ( z_flag && (n_flag != v_flag) ) do_jump = 1'b1;	  // LE
      4'b1110: do_jump = 1'b1;                                        // ALWAYS
      default: do_jump = 0; 				                                  // Otherwise
    endcase
  end

  // ************************************
  // ******** LOADING & STORING *********
  // ************************************
  reg [31:0] mem_addr;
  wire r_not_w;
  assign r_not_w = 1'b1;
  reg [31:0] mem_data_o;
  wire U_bit = inst[23]; // 1 = add, 0 = subtract from base

  memory mem ( .clk_i(clk), .data_addr_i(mem_addr), .data_i(r2), .r_not_w_i(r_not_w), .data_o(mem_data_o) );

  //store data in memory
  always @(posedge clk) begin
    if ( instruction_codes == 3'b010 && ~s_bit ) // also L bit for load and Store
      if( U_bit )
        mem_addr <= rd_address + inst[11:0];
      else
        mem_addr <= rd_address - inst[11:0];
    else
      mem_addr <= mem_addr;
  end

  // ************************************
  // **** WRITING BACK TO REGISTERS *****
  // ************************************

  // UPDATES write address
  always @(*) begin   // Check with Manual
    if ( instruction_codes == 3'b101 )  // Branch
      rd_address = 4'b1110;
    else
      rd_address = inst[12+:4];
  end

  // ************************************
  // **** BRANCHING and INCREMENT *******
  // ************************************
  reg [1:0] pc_state_n, pc_state_r;
  // 2'b00 : Fetch Instructions
  // 2'b01 : Read Registers
  // 2'b10 : Deal with Memory
  // 2'b11 : Write Back

  initial begin
    pc_r = 0;
    pc_state_r = 2'b00;
  end

  always @(*) begin
    if ( pc_state_r == 4 )
      pc_state_n = 0;
    else
      pc_state_n = pc_state_r + 1;
  end

  always @(*) begin
    if ( pc_state_r == 2'b00 )
      if ( instruction_codes == 3'b101 && do_jump )   // Does Branch with Conditions
        pc_n = pc_r + 8 + { {6{branch_address[23]}}, branch_address, 2'b0 };
      else
        pc_n = pc_r >= 64 ? 0 : pc_r + 4;
    else
      pc_n = pc_r;
  end

  always @(posedge clk) begin  // CHANGE 4 STAGE CLK CYCLE 1. FETCH INST 2. READ REGISTERS/COMPUTE 3. MEM 4. WRITE
    pc_state_r <= pc_state_n;
    pc_r <= pc_n;
  end

  // Controls the LED on the board.
  assign led = 1'b0;

  // These are how you communicate back to the serial port debugger.
  assign debug_port1 = pc_r[0+:8];
  assign debug_port2 = r1[0+:8];
  assign debug_port3 = r2[0+:8];
  assign debug_port4 = operand2[0+:8];
  assign debug_port5 = data[0+:8];
  assign debug_port6 = { do_jump, 1'b0, n_flag, z_flag, 2'b0, c_flag, v_flag };
  assign debug_port7 = mem_data_o;

endmodule
