module execute (
    input clk_i
  , input [31:0] r1_i
  , input [31:0] r2_i
  , input [3:0] r1_addr_i
  , input [3:0] r2_addr_i
  , input [3:0] rd_addr_i
  , input [31:0] inst_i
  , input [31:0] wb_data_i
  , input [3:0] wb_addr_i
  , input wb_en_i
  , input stall_i
  , input valid_i
  , input flush_i
  , output [31:0] inst_o
  , output [31:0] ALU_data_o
  , output [31:0] CPSR_o;
  , output stall_o
  , output valid_o
  , output flush_o
  , output branch_o
  , output [3:0] rd_addr_o
  , output do_write_o
);
  /////////// Init statements /////////////
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [31:0] operand2;
  wire s_bit;
  reg [3:0] update_flags;
  reg flush_o;
  wire [31:0] r1;
  wire [31:0] r2;
  wire [3:0] cond;

  /////////// Assign statements ///////////
  assign opcode = inst_i[21+:4];
  assign instruction_codes = inst_i[25+:3];
  assign immediate = inst_i[0+:8];
  assign rotate = inst_i[8+:4];
  assign stall_o = stall_i; // NEEDS TO BE FIXED
  assign s_bit = inst_i[20];
  assign cond = inst_i[28+:4];

  //////////// pipeline registers ////////////
  always @(posedge clk_i) begin
    inst_o <= inst_i;
  end

  //////////// Setting Valid ////////////
  always @(posedge clk_i)
    if ( flush_i || ( cond_met && branch_o ) )
      valid_o <= 1'b0;
    else
      valid_o <= valid_i;

  /////////// Setting Flush ////////////
  always @(posedge clk_i)
    if ( flush_i || ( cond_met && branch_o ) )
      flush_o <= 1'b1;
    else
      flush_o <= flush_i;

  //////////////// ALU ////////////////
  ALU ALU_module (
    .instruction_codes( inst_i )
    , .opcode( opcode )
    , .a( r2_ALU )
    , .b( r1_ALU )
    , .cond( cond )
    , .s_bit( s_bit )
    , .data( ALU_data_o )
    , .CPSR( CPSR_o )
    , .cond_met( cond_met )
  );

  // ************************************
  // ************ BRANCHING *************
  // ************************************
  always @(*)
    if ( cond_met && instruction_codes == 3'b101 )
      branch_o = 1'b1;
    else
      branch_o = 1'b0;

  // ************************************
  // *********** Data Hazard ************
  // ************************************
  always @(*) begin
    if (wb_addr_i == r1_addr_i && wb_en_i)
      r1 = wb_data_i;
    else if (rd_addr_o == r1_addr_i && valid_o && do_write_o)
      r1 = ALU_data_o;
    else
      r1 = r1_i;
    if (wb_addr_i == r2_addr_i && wb_en_i)
      r2 = wb_data_i;
    else if (rd_addr_o == r2_addr_i && valid_o && do_write_o)
      r2 = ALU_data_o;
    else
      r2 = r2_i;
  end

  // ************************************
  // ********* r1(rm) selection *********
  // ************************************
  wire [31:0] r1_shift;
  wire [31:0] r1_ALU;
  wire [31:0] r2_ALU;
  rotate rot ( rotate, immediate, operand2 );
  shifter shifting (  .inst_i(inst_i[11:5])
                    , .r1_i(r1)
                    , .r1_shift_o(r1_shift)
                    );
  assign r1_ALU = instruction_codes == 3'b000 ? r1_shift : operand2;
  assign r2_ALU = r2;

  // ************************************
  // ************** DO_WRITE ************
  // ************************************
  always @(*) begin
    if ( cond_met )
      if ( ( instruction_codes == 3'b000 || instruction_codes == 3'b001 ) && s_bit ) // if write to registers and normal op
        do_write_o = 1'b1;
      else if ( instruction_codes == 3'b010 && s_bit = 1'b0 ) // writes only if Storing to Mem and not LOAD
        do_write_o = 1'b1;
      else
        do_write_o = 1'b0;
    else
      do_write_o = 1'b0;
  end

endmodule
