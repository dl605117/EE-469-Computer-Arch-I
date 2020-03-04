module ALU (
    input clk_i
  , input [2:0] instruction_codes
  , input reset_i
  , input [3:0] opcode
  , input [31:0] a, b
  , input [3:0] cond
  , input s_bit
  , output [31:0] ALU_data
  , output [31:0] CPSR
  , output cond_met
);
wire [32:0] data;
assign ALU_data = data[0+:32];
// a = rn or r2
// b = rm (muxed in as rm or operand2) or r1
wire [31:0] b_temp;
assign b_temp = ~b;

  always @(*) begin
    case( opcode ) //add instruction bits 21 to 24
      4'b0000: data = a & b;           //and
      4'b0001: data = a ^ b;           //exclusive or
      4'b0010: data = a + b_temp + 1;           //sub
      4'b0100: data = a + b;           //add
      4'b1000: data = a & b;          //test
      4'b1001: data = a ^ b;           //test equivalence
      4'b1010: data = a + b_temp + 1;           //compare
      4'b1100: data = a | b;          //orr
      4'b1101: data = b;                //move, need to check, it says operand2 which is 12 bits long
      4'b1110: data = ~a & b;         //bit clear
      4'b1111: data = 8'hFFFFFFFF ^ b;   //move not
      default: data = 32'b0;                       // not sure
    endcase
  end

  // ************************************
  // ************ FLAGS *****************
  // ************************************
  // a = rn or r2
  // b = rm (muxed in as rm or operand2) or r1

  reg n_flag, v_flag, z_flag, c_flag;
  wire [3:0] update_flags;
  assign CPSR = { n_flag, z_flag, c_flag, v_flag, 22'b0, 5'b11111 };

  // UPDATING FLAGS
  always @(posedge clk_i) begin
    if (reset_i) begin
      n_flag <= 0;
      z_flag <= 0;
      c_flag <= 0;
      v_flag <= 0;
    end else begin
      if ( update_flags[3] )
        n_flag <= data[31];     // negative flag
      else
        n_flag <= n_flag;

      if ( update_flags[2] )
        z_flag <= (data == 0);     // zero flag
      else
        z_flag <= z_flag;

      if ( update_flags[1] )
        c_flag <= data[32];     // carry flag
      else
        c_flag <= c_flag;

      if ( update_flags[0] )   // overflow flag
          v_flag <= (opcode == 4'b0100) ? b[31] & a[31] && (!data[31]) || (!b[31] & !a[31] && data[31])
                : (b[31] & !a[31] && data[31]) || (b_temp[31] & a[31] && !data[31]);
      else
        v_flag <= v_flag;
    end
  end

  //4'bxxxx : {n_flag, z_flag, c_flag, v_flag}
  // SETTING UPDATE FLAGS
  always @(*) begin
    if ( s_bit & ( instruction_codes == 3'b000 | instruction_codes == 3'b001 ) ) begin
      case ( opcode )
        4'b0000: update_flags = 4'b1110;  // AND
        4'b0001: update_flags = 4'b1110;  // XOR
        4'b0010: update_flags = 4'b1111;  // SUB
        4'b0100: update_flags = 4'b1111;  // ADD
        4'b1000: update_flags = 4'b1110;  // TEST
        4'b1001: update_flags = 4'b1110;  // TESTQ
        4'b1010: update_flags = 4'b1111;  // COMPARE
        4'b1100: update_flags = 4'b1110;  // OR
        4'b1101: update_flags = 4'b1110;  // MOV
        4'b1110: update_flags = 4'b0000;  // BIT CLEAR
        4'b1111: update_flags = 4'b1110;  // MOVE NOT
        default: update_flags = 4'b0000;  // EVERYTHING ELSE
      endcase
    end
    else begin
      update_flags = 4'b0000;    // RESETTING
    end
  end

  // ************************************
  // ******* CHECKING CONDITIONS ********
  // ************************************
  // cond code

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

endmodule
