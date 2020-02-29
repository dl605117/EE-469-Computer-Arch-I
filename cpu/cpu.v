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
  // stall(find cases for other stall)

  reg [31:0] inst;
  wire [31:0] CPSR;
  reg [31:0] pc_r, pc_n;
  wire [31:0] operand2;
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] r1_address;
  wire [3:0] r2_address;
  wire [3:0] opcode;
  wire [2:0] instruction_codes;
  reg [31:0] r1_preshift;
  reg [32:0] data;
  reg do_write;
  wire s_bit; // also L bit for load and Store
  wire [7:0] immediate;
  wire [3:0] rotate;
  wire [23:0] branch_address;
  wire [31:0] r1; //post shift r1
  wire [31:0] r2;

  assign branch_address = inst[0+:24];
  assign rn_address = inst[16+:4];    // r2
  assign rm_address = inst[0+:4];     // r1
  assign opcode = inst[21+:4];
  assign instruction_codes = inst[25+:3];
  assign rotate = inst[8+:4];
  assign immediate = inst[0+:8];

  wire [31:0] wb_data;
  wire [3:0] wb_addr;
  wire wb_en;

  wire branch, pc_wb, pc;
  wire [31:0] inst;
  wire [31:0] exec_data;

  fetch fetch_module (
      .clk_i( clk )
    , .branch_i( branch )
    , .pc_wb_i( pc_wb )
    , .data_i( exec_data )
    , .flush_i( flush_decode_to_flush )
    , .valid_o( valid_fetch_to_decode )
    , .inst_o( inst )
    , .pc( pc )
  );

  wire inst_fetch_to_decode;
  wire valid_fetch_to_decode;
  wire wb_en;
  wire flush_decode_to_flush;

  decode_reg_r decode_module (
      .clk_i( clk )
    , .pc_i( pc )
    , .inst_i( inst_fetch_to_decode )
    , .valid_i( valid_fetch_to_decode )
    , .flush_i( flush_exec_to_decode )
    , .wb_data_i( wb_data )
    , .wb_addr_i( wb_addr )
    , .wb_en_i( wb_en )
    , .valid_o( valid_rm_to_exec )
    , .r1_o( r1_rm_to_exec )
    , .r2_o( r2_rm_to_exec )
    , .inst_o( instr_rm_to_exec )
    , .r1_addr_o( r1_addr_rm_to_exec )
    , .r2_addr_o( r2_addr_rm_to_exec )
    , .rd_addr_o( rd_addr_rm_to_exec )
  );

  wire flush_exec_to_decode;
  wire valid_rm_to_exec;
  wire r1_rm_to_exec;
  wire r2_rm_to_exec;
  wire r1_addr_rm_to_exec;
  wire r2_addr_rm_to_exec;
  wire rd_addr_rm_to_exec;
  wire instr_rm_to_exec;

  execute execute_module (
      .clk_i( clk )
    , .r1_i( r1_rm_to_exec )
    , .r2_i( r2_rm_to_exec )
    , r1_addr_i( r1_addr_rm_to_exec )
    , r2_addr_i( r2_addr_rm_to_exec )
    , rd_addr_i( rd_addr_rm_to_exec )
    , inst_i( instr_rm_to_exec )
    , wb_data_i( )
    , wb_addr_i
    , wb_en_i
    , stall_i
    , valid_i()
    , inst_o
    , ALU_data_o
    , CPSR_o;
    , stall_o
    , valid_o
    , flush_o
    , branch_o
    , rd_addr_o
    , do_write_o
  );


  // ************************************
  // ******** LOADING & STORING *********
  // ************************************
  reg [31:0] mem_addr;
  wire r_not_w;
  assign r_not_w = ~(pc_state_r == write && instruction_codes == 3'b010 && ~s_bit);
  wire [31:0] mem_data_o;
  wire U_bit = inst[23]; // 1 = add, 0 = subtract from base

  memory mem ( .clk_i(clk), .data_addr_i(mem_addr), .data_i(r1_preshift), .r_not_w_i(r_not_w), .data_o(mem_data_o) );

  //store data in memory
  always @(posedge clk) begin
    if ( pc_state_n == exec_mem )
      if ( instruction_codes == 3'b010 && ~s_bit ) // also L bit for load and Store 1 = Load 0 = Store
        if( U_bit )
          mem_addr <= r2 + inst[11:0];
        else
          mem_addr <= r2 - inst[11:0];
      else
        mem_addr <= mem_addr;
    else
      mem_addr <= mem_addr;
  end


  // Controls the LED on the board.
  assign led = 1'b0;

  // These are how you communicate back to the serial port debugger.
  assign debug_port1 = pc_r[0+:8];
  assign debug_port2 = r1_preshift[31:24];
  assign debug_port3 = r2[0+:8];
  assign debug_port4 = operand2[0+:8];
  assign debug_port5 = data[31:24];
  assign debug_port6 = mem_data_o; //{ cond_met, 1'b0, n_flag, z_flag, 2'b0, c_flag, v_flag };
  assign debug_port7 = mem_addr[0+:8];


endmodule
