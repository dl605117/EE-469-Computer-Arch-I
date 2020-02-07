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
  // Change PC Clk period update to 4
  // fix load and STORE
  //    ADD mem module
  // complete Condition Codes
  // clean up OPERATIONS
  // write BACK



  reg [31:0] inst;
  reg [31:0] pc;
  wire [31:0] operand2;
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  reg [31:0] r1, r2, rd;
  reg [32:0] data;
  wire do_write;
  reg toggle_pc_update, comb_toggle_pc_update; // toggle_read might not be neccessary
  wire s_bit;
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [23:0] branch_address;

  assign s_bit = inst[20];
  //assign rd = inst[12+:4];
  assign branch_address = inst[0+:24];
  assign rn_address = inst[16+:4];    // r1
  assign rm_address = inst[0+:4];     // r2
  assign opcode = inst[21+:4];
  assign instruction_codes = inst[25+:3];
  assign do_write = 1'b0; // for now, will not write to register_file
  assign rotate = inst[8+:4];
  assign immediate = inst[0+:8];

  code_memory cm ( pc, inst );
  register_file rf ( clk, rm_address, rn_address, do_write, rd_address, data[0+:32], r1, r2 );
  rotate rot ( rotate, immediate, operand2 );

  // ************************************
  // ***** NORMAL OPERATIONS & BL *******
  // ************************************
  always @(*) begin
    data = 0;
    if ( instruction_codes == 3'b010)    // LOAD AND STORE
      if(inst[20] == 1)
        if(inst[23] == 1)
          data = r2 + inst[11:0];
        else
          data = r2 - inst[11:0];
      else
        data = rd_address + inst[11:0];
    else if ( instruction_codes == 3'b101 && do_jump )    // Setting Link Address for Branch
      data = inst[24] ? pc + 4 : 0;
    else
      data = ALU_data;
  end

  wire [31:0] ALU_data;
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

    if ( update_flags[3] )
      v_flag = data[32];     // overflow flag
    else
      if(instruction_codes = 3'b001)
        v_flag = (opcode == 4'b0100) ? operand2[31] & r2[31] && (!data[31]) || (!operand2[31] & !r2[31] && data[31])
              : !operand2[31] & r2[31] && (!data[31]) || (operand2[31] & !r2[31] && data[31]);
      else
        v_flag = (opcode == 4'b0100) ? r1[31] & r2[31] && (!data[31]) || (!r1[31] & !r2[31] && data[31])
              : r1[31] & !r2[31] && (!data[31]) || (!r1[31] & r2[31] && data[31]);
  end

  //4'bxxxx : {n_flag, z_flag, c_flag, v_flag}
  // SETTING UPDATE FLAGS
  always @( posedge clk ) begin
    if ( ~toggle_pc_update & s_bit & ( instruction_codes == 3'b000 | instruction_codes == 3'b001 ) ) begin
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

  //store data in memory
  // always @(posedge clk) begin
  //   if (inst[27:25] == 010 && inst[20] == 0)
  //     if(inst[23] == 1)
  //       memory[r2 + inst[11:0]] <= st_data;
  //     else
  //       memory[r2 - inst[11:0]] <= st_data;
  //   end
  // end

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
  initial begin
    toggle_pc_update = 1'b1;
    pc = 32'b0;
  end

  always @(*)
    comb_toggle_pc_update = toggle_pc_update ^ 1'b1;

  always @(posedge clk) begin  // CHANGE 4 STAGE CLK CYCLE 1. FETCH INST 2. READ REGISTERS/COMPUTE 3. MEM 4. WRITE
    toggle_pc_update <= comb_toggle_pc_update;
    if ( toggle_pc_update )
      if ( instruction_codes == 3'b101 && do_jump )   // Does Branch with Conditions
        pc <= pc + 8 + { {6{branch_address[23]}}, branch_address, 2'b0 };
      else
        pc <= pc >= 64 ? 0 : pc + 4;
    else
      pc <= pc;
  end

  // Controls the LED on the board.
  assign led = 1'b0;

  // These are how you communicate back to the serial port debugger.
  assign debug_port1 = pc[0+:8];
  assign debug_port2 = r1[0+:8];
  assign debug_port3 = r2[0+:8];
  assign debug_port4 = operand2[0+:8];
  assign debug_port5 = data[0+:8];
  assign debug_port6 = { do_jump, 1'b0, n_flag, z_flag, 2'b0, c_flag, v_flag };
  assign debug_port7 = opcode;

endmodule
