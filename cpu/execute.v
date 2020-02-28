module execute (
    input clk_i
  , input [31:0] r1_i
  , input [31:0] r2_i
  , input [31:0] inst_i
  , input stall_i
  , input valid_i
  , output [31:0] inst_o
  , output [31:0] ALU_data_o
  , output stall_o
  , output valid_o
  , output flush_o
  , output branch
);
  /////////// Init statements /////////////
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [31:0] operand2;
  wire s_bit;
  wire n_flag, v_flag, z_flag, c_flag;
  reg [3:0] update_flags;
  reg flush_o;
  wire branch;
  wire [31:0] CPSR;

  /////////// Assign statements ///////////
  assign opcode = inst_i[21+:4];
  assign instruction_codes = inst_i[25+:3];
  assign immediate = inst[0+:8];
  assign rotate = inst[8+:4];
  assign stall_o = stall_i; // NEEDS TO BE FIXED
  assign s_bit = inst[20];
  assign inst_o = inst_i;
  assign CPSR = { n_flag, z_flag, c_flag, v_flag, 22'b0, 5'b11111 };

  //////////// Setting Valid ////////////
  always @(posedge clk_i)
    if ( cond_met )
      if ( branch ) begin
        valid_o <= 1'b0;
        flush_o <= 1'b1;
      end
      else begin
        valid_o <= valid_i;
        flush_o <= 1'b0;
      end
    else begin
      valid_o <= 1'b0;
      flush_o <= 1'b0;
    end

  //////////////// Modules ////////////////
  rotate rot ( rotate, immediate, operand2 );
  ALU alu (.instruction_codes(instruction_codes), .opcode(opcode), .a(r2_i), .b(r1_i), .data(ALU_data_o));

  // ************************************
  // ************ FLAGS *****************
  // ************************************
  // UPDATING FLAGS
  always @(*) begin
    if ( update_flags[3] )
      n_flag = data[31];     // negative flag
    else
    n_flag = n_flag;

    if ( update_flags[2] )
      z_flag = (data == 0);     // zero flag
    else
      z_flag = z_flag;

    if ( update_flags[1] )
      c_flag = data[32];     // carry flag
    else
      c_flag = c_flag;

    if ( update_flags[0] )   // overflow flag
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
    if ( s_bit & ( instruction_codes == 3'b000 | instruction_codes == 3'b001 ) ) begin
      case ( opcode )
        4'b0000: update_flags <= 4'b1110;  // AND
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
  wire cond_met;

  always @(*) begin
    cond_met = 1'b0;
    case ( cond )    // Checking Condition Codes for Jump
      4'b0000: if ( z_flag ) cond_met = 1'b1;                          // EQ
      4'b0001: if ( ~z_flag ) cond_met = 1'b1;				                  // NE
      4'b0010: if ( c_flag ) cond_met = 1'b1;				                  // CS/HS
      4'b0011: if ( ~c_flag ) cond_met = 1'b1; 				                // CC/LO
      4'b0100: if ( n_flag ) cond_met = 1'b1; 				                  // MI
      4'b0101: if ( ~n_flag ) cond_met = 1'b1;				                  // PL
      4'b0110: if ( v_flag ) cond_met = 1'b1;				                  // VS
      4'b0111: if ( ~v_flag ) cond_met = 1'b1; 				                // VC
      4'b1000: if ( c_flag && ~z_flag ) cond_met = 1'b1; 			        // HI
      4'b1001: if ( ~c_flag && z_flag ) cond_met = 1'b1;			          // LS
      4'b1010: if ( n_flag == v_flag ) cond_met = 1'b1; 		            // GE
      4'b1011: if ( n_flag != v_flag ) cond_met = 1'b1;		            // LT
      4'b1100: if ( ~z_flag && (n_flag == v_flag) ) cond_met = 1'b1; 	// GT
      4'b1101: if ( z_flag && (n_flag != v_flag) ) cond_met = 1'b1;	  // LE
      4'b1110: cond_met = 1'b1;                                        // ALWAYS
      default: cond_met = 0; 				                                  // Otherwise
    endcase
  end

  // ************************************
  // ************ BRANCHING *************
  // ************************************
  always @(*)
    if ( cond_met && instruction_codes == 3'b101 )
      branch = 1'b1;
    else
      branch = 1'b0;

endmodule
