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
  // check stall and flush
  // Check PC + 4
  // valid after branch needs to be fixed
  // add after load takes forever / stall takes a while
  //    stall lasts forever, need to figure out how to stop it.

  wire reset = 1'b0;

  wire [31:0] wb_data;
  wire [3:0] wb_addr;
  wire wb_en;

  wire branch;
  wire [23:0] branch_address;
  wire pc_wb;
  wire [31:0] pc;
  wire [31:0] inst_fetch_to_decode;
  wire valid_fetch_to_decode;
  wire flush_decode_to_flush;
  wire stall_decode_to_fetch;
  wire stall_exec_to_decode;
  wire flush_exec_to_decode;
  wire valid_rm_to_exec;
  wire [31:0] r1_rm_to_exec;
  wire [31:0] r2_rm_to_exec;
  wire [3:0] r1_addr_rm_to_exec;
  wire [3:0] r2_addr_rm_to_exec;
  wire [3:0] rd_addr_rm_to_exec;
  wire [31:0] instr_rm_to_exec;
  wire stall_exec_to_rm;
  wire [31:0] CPSR;
  wire do_write_exec_to_mem;
  wire [31:0] alu_data_exec;
  wire valid_exec_to_mem;
  wire flush_mem_to_exec;
  wire [3:0] rd_addr_exec_to_mem;
  wire [31:0] inst_exec_to_mem;
  wire [31:0] rd_data_exec_to_mem;
  wire flush_wb_to_mem;
  wire [31:0] alu_data_mem;
  wire [31:0] mem_data_mem_to_wb;
  wire [3:0] wb_addr_mem_to_wb;
  wire valid_mem_to_wb;
  wire load_mem_wb;
  wire do_write_mem_to_wb;


  fetch fetch_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .branch_i( branch )
    , .branch_address_i( branch_address )
    , .pc_wb_i( pc_wb )
    , .data_i( wb_data )
    , .flush_i( flush_decode_to_flush )
    , .stall_i( stall_exec_to_decode )
    , .valid_o( valid_fetch_to_decode )
    , .inst_o( inst_fetch_to_decode )
    , .pc( pc )
  );



  decode_reg_r decode_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .inst_i( inst_fetch_to_decode )
    , .valid_i( valid_fetch_to_decode )
    , .flush_i( flush_exec_to_decode )
    , .wb_data_i( wb_data )
    , .wb_addr_i( wb_addr )
    , .wb_en_i( wb_en )
    , .stall_i( stall_exec_to_decode )
    , .valid_o( valid_rm_to_exec )
    , .r1_o( r1_rm_to_exec )
    , .r2_o( r2_rm_to_exec )
    , .inst_o( instr_rm_to_exec )
    , .r1_addr_o( r1_addr_rm_to_exec )
    , .r2_addr_o( r2_addr_rm_to_exec )
    , .rd_addr_o( rd_addr_rm_to_exec )
    , .stall_o( stall_decode_to_fetch )
    , .flush_o( flush_decode_to_flush )
  );

  wire cond_met;
  wire [2:0] inst_codes_test;
	wire [2:0] counting_stalls;
	wire r_not_w;
	wire [31:0] register_ALU;
  execute execute_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .r1_i( r1_rm_to_exec )
    , .r2_i( r2_rm_to_exec )
    , .r1_addr_i( r1_addr_rm_to_exec )
    , .r2_addr_i( r2_addr_rm_to_exec )
    , .rd_addr_i( rd_addr_rm_to_exec )
    , .inst_i( instr_rm_to_exec )
    , .wb_data_i( wb_data )
    , .wb_addr_i( wb_addr )
    , .wb_en_i( wb_en )
    , .valid_i( valid_rm_to_exec )
    , .flush_i( flush_mem_to_exec )
    , .pc_i( pc )
    , .inst_o( inst_exec_to_mem )
    , .ALU_data_o( alu_data_exec )
    , .CPSR_o( CPSR )
    , .stall_o( stall_exec_to_decode )
    , .valid_o( valid_exec_to_mem )
    , .flush_o( flush_exec_to_decode )
    , .branch_o( branch )
    , .branch_address_o (branch_address)
    , .rd_addr_o( rd_addr_exec_to_mem )
    , .do_write_o( do_write_exec_to_mem )
    , .rd_data_o( rd_data_exec_to_mem )
    , .cond_met_t( cond_met )
    , .instruction_codes_t( inst_codes_test )
	 , .counting_stalls( counting_stalls )
	 , .register_ALU( register_ALU )
  );

wire [31:0] tester_reg;

  mem memory_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .ALU_data_i( alu_data_exec )
    , .store_data_i( rd_data_exec_to_mem )
    , .inst_i( inst_exec_to_mem )
    , .valid_i( valid_exec_to_mem )
    , .flush_i( flush_wb_to_mem )
    , .do_write_i( do_write_exec_to_mem  )
    , .ALU_data_o( alu_data_mem )
    , .mem_data_o( mem_data_mem_to_wb )
    , .wb_addr_o( wb_addr_mem_to_wb ) // write back address for register file
    , .valid_o( valid_mem_to_wb )
    , .do_write_o( do_write_mem_to_wb )
    , .load_o( load_mem_wb )
    , .flush_o( flush_mem_to_exec )
	 , .r_not_w( r_not_w )
	 , .tester_reg( tester_reg )
  );

  write_back wb_module(
      .mem_data_i( mem_data_mem_to_wb )
    , .ALU_data_i( alu_data_mem )
    , .load_i( load_mem_wb )
    , .valid_i( valid_mem_to_wb )
    , .do_write_i( do_write_mem_to_wb )
    , .wb_addr_i( wb_addr_mem_to_wb )
    , .wb_en_o( wb_en )
    , .wb_data_o( wb_data )
    , .wb_addr_o( wb_addr )
    , .pc_wb_o( pc_wb )
    , .flush_o( flush_wb_to_mem )
  );

  // Controls the LED on the board.
  assign led = 1'b0;

  // These are how you communicate back to the serial port debugger.
  assign debug_port1 = pc[0+:8];
  assign debug_port2 = r1_rm_to_exec[0+:8];
  assign debug_port3 = r2_rm_to_exec[0+:8];
  assign debug_port4 = alu_data_exec[0+:8];
  assign debug_port5 = tester_reg[0+:8];//rd_data_exec_to_mem[0+:8]; //inst_fetch_to_decode[19:16];
  assign debug_port6 = rd_data_exec_to_mem[0+:8];/*{ wb_en
                        , branch
                        , pc_wb
                        , flush_exec_to_decode
								, counting_stalls[0+:2]
                        , stall_exec_to_decode
                        , valid_fetch_to_decode
                        };//mem_data_o; //{ cond_met, 1'b0, n_flag, z_flag, 2'b0, c_flag, v_flag };*/
  assign debug_port7 = { 5'b0, inst_codes_test };//{ 2'b0, valid_exec_to_mem, r_not_w, alu_data_exec[0+:4] };//{ r1_addr_rm_to_exec, r2_addr_rm_to_exec };//{ 4'b0, cond_met, inst_codes_test };//mem_addr[0+:8];


endmodule
