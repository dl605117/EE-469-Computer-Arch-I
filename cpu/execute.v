module execute (
    input wire clk_i
  , input wire reset_i
  , input wire [31:0] r1_i
  , input wire [31:0] r2_i
  , input wire [3:0] r1_addr_i
  , input wire [3:0] r2_addr_i
  , input wire [3:0] rd_addr_i
  , input wire [31:0] inst_i
  , input wire [31:0] wb_data_i
  , input wire [3:0] wb_addr_i
  , input wire wb_en_i
  , input wire valid_i
  , input wire flush_i
  , input wire [31:0] pc_i
  , output reg [31:0] inst_o
  , output reg [31:0] ALU_data_o
  , output wire [31:0] CPSR_o
  , output wire stall_o
  , output reg valid_o
  , output reg flush_o
  , output wire branch_o
  , output wire [23:0] branch_address_o
  , output reg [3:0] rd_addr_o
  , output reg do_write_o
  , output reg [31:0] rd_data_o
  , output cond_met_t
  , output [2:0] instruction_codes_t
  , output [2:0] counting_stalls
  , output [31:0] register_ALU
);

  reg branch;

  /////////// Init statements /////////////
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [31:0] operand2;
  wire s_bit;
  reg [3:0] update_flags;
  reg [31:0] r1;
  reg [31:0] r2;
  wire [3:0] cond;
  wire [31:0] ALU_data;
  reg do_write;
  wire [3:0] ALU_opcode;
  wire U_bit;
  wire cond_met;
  wire [31:0] r1_shift;
  wire [31:0] r1_ALU;
  wire [31:0] r2_ALU;
  reg stall;

  /////////// Assign statements ///////////
  assign branch_o = branch;

  assign cond_met_t = cond_met;
  assign instruction_codes_t = instruction_codes;

  assign opcode = inst_i[21+:4];
  assign instruction_codes = inst_i[25+:3];
  assign immediate = inst_i[0+:8];
  assign rotate = inst_i[8+:4];
  //assign stall_o = stall_i; // NEEDS TO BE FIXED
  assign branch_address_o = inst_i[0+:24];
  assign s_bit = inst_i[20];
  assign cond = inst_i[28+:4];
  assign U_bit = inst_i[23];
  assign ALU_opcode = instruction_codes == 3'b010 ? U_bit ? 4'b0100 : 4'b0010 : opcode;


  //////////// pipeline registers ////////////
  always @(posedge clk_i) begin
    if(reset_i) begin
      inst_o <= 0;
      ALU_data_o <= 0;
      do_write_o <= 0;
      rd_addr_o <= 0;
      rd_data_o <= 0;
    end else begin
        inst_o <= inst_i;
        ALU_data_o <= ALU_data;
        do_write_o <= do_write;
        rd_addr_o <= rd_addr_i;
        rd_data_o <= ( rd_addr_o == r1_addr_i ) ? ALU_data_o : r1_i;
    end
  end

  //////////// Setting Valid ////////////
  always @(posedge clk_i) begin
    if(reset_i) begin
      valid_o <= 1'b0;
    end else begin
        if ( flush_i || ( branch_o ) || ~cond_met || stall )
          valid_o <= 1'b0;
        else
          valid_o <= valid_i;
    end
  end

  /////////// Setting Flush ////////////
  always @(*) begin
      if ( flush_i || ( branch_o ) )
        flush_o = 1'b1;
      else
        flush_o = 1'b0;
  end

  //////////////// ALU ////////////////
  ALU ALU_module (
      .clk_i( clk_i )
    , .instruction_codes( instruction_codes )
    , .reset_i(reset_i)
    , .opcode( ALU_opcode )
    , .a( r2_ALU )
    , .b( r1_ALU )
    , .cond( cond )
    , .s_bit( s_bit )
    , .ALU_data( ALU_data )
    , .CPSR( CPSR_o )
    , .cond_met( cond_met )
  );

  // ************************************
  // ************ BRANCHING *************
  // ************************************
  always @(*) begin
    if ( cond_met & (instruction_codes == 3'b101) )
      branch = 1'b1;
    else
      branch = 1'b0;
  end

  // ************************************
  // *********** Data Hazard ************
  // ************************************
  always @(*) begin
    if (wb_addr_i == r1_addr_i && wb_en_i)
      r1 = wb_data_i;
    else if (rd_addr_o == r1_addr_i && valid_o && do_write_o)
      r1 = ALU_data_o;
    else if (r1_addr_i == 4'b1111)
      r1 = pc_i;
    else
      r1 = r1_i;
    if (wb_addr_i == r2_addr_i && wb_en_i)
      r2 = wb_data_i;
    else if (rd_addr_o == r2_addr_i && valid_o && do_write_o)
      r2 = ALU_data_o;
    else if (r2_addr_i == 4'b1111)
      r2 = pc_i;
    else
      r2 = r2_i;
  end

  // ************************************
  // ********* r1(rm) selection *********
  // ************************************

  rotate rot ( rotate, immediate, operand2 );
  shifter shifting (  .inst_i(inst_i[11:5])
                    , .r1_i(r1)
                    , .r1_shift_o(r1_shift)
                    );

  assign r1_ALU = (instruction_codes == 3'b010 && ~s_bit) ? {20'b0, inst_i[0+:12]} :
                  instruction_codes == 3'b000 ? r1_shift : operand2;
  assign r2_ALU = r2;
  assign register_ALU = r2;

  // ************************************
  // ************** DO_WRITE ************
  // ************************************
  // solely for writebacks to register file
  always @(*) begin
    if ( cond_met && valid_i)
      if ( ( instruction_codes == 3'b000 || instruction_codes == 3'b001 ) && s_bit ) // if write to registers and normal op
        do_write = 1'b1;
      else if ( instruction_codes == 3'b010 && s_bit == 1'b1 ) // Only write if LOADing
        do_write = 1'b1;
      else
        do_write = 1'b0;
    else
      do_write = 1'b0;
  end

  // ************************************
  // ************** Stalling ************
  // ************************************
	//reg counting_stalls;
	//reg counting_stalls_in;
	wire [3:0] instruction_codes_old;
  assign instruction_codes_old = inst_o[25+:3];


	reg [2:0] counting_stalls_r;
	reg [2:0] counting_stalls_n;
	assign counting_stalls = counting_stalls_r;

	always @(*)
		if ( stall )
			counting_stalls_n = counting_stalls_r + 1;
		else
			counting_stalls_n = 3'b0;

	always @(posedge clk_i)
		if ( reset_i )
			counting_stalls_r <= 3'b0;
		else
			counting_stalls_r <= counting_stalls_n;


  always @(*) begin
    if (instruction_codes_old == 3'b010 & valid_o)
      if(instruction_codes == 3'b000)
        stall = (r1_addr_i == rd_addr_o | r2_addr_i == rd_addr_o );
      else if (instruction_codes == 3'b001)
        stall = (r2_addr_i == rd_addr_o);
      else
        stall = 0;
    else
      stall = 0;
  end

  assign stall_o = ( counting_stalls_n != 3'b111 && counting_stalls_n != 3'b000 );

endmodule
