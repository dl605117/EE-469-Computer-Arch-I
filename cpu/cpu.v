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

  reg reset;

  wire [31:0] wb_data;
  wire [3:0] wb_addr;
  wire wb_en;

  wire branch, pc_wb, pc;

  fetch fetch_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .branch_i( branch )
    , .pc_wb_i( pc_wb )
    , .data_i( wb_data )
    , .flush_i( flush_decode_to_flush )
    , .stall_i( stall_decode_to_fetch )
    , .valid_o( valid_fetch_to_decode )
    , .inst_o( inst_fetch_to_decode )
    , .pc( pc )
  );

  wire inst_fetch_to_decode;
  wire valid_fetch_to_decode;
  wire flush_decode_to_flush;
  wire stall_decode_to_fetch;

  decode_reg_r decode_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .pc_i( pc )
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

  wire flush_exec_to_decode;
  wire valid_rm_to_exec;
  wire r1_rm_to_exec;
  wire r2_rm_to_exec;
  wire r1_addr_rm_to_exec;
  wire r2_addr_rm_to_exec;
  wire rd_addr_rm_to_exec;
  wire instr_rm_to_exec;
  wire stall_exec_to_decode;

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
    , .valid_i( valid_mem_to_exec )
    , .inst_o( inst_exec_to_mem )
    , .ALU_data_o( alu_data_exec )
    , .CPSR_o( CPSR )
    , .stall_o( stall_exec_to_decode )
    , .valid_o( valid_exec_to_mem )
    , .flush_o( flush_mem_to_exec )
    , .branch_o( branch )
    , .rd_addr_o( rd_addr_exec_to_mem )
    , .do_write_o( do_write_exec_to_mem )
  );

  wire alu_data_exec;
  wire valid_exec_to_mem;
  wire flush_mem_to_exec;
  wire rd_addr_exec_to_mem;
  wire do_write_exec_to_mem;
  wire inst_exec_to_mem;

  mem memory_module (
      .clk_i( clk )
    , .reset_i( reset )
    , .ALU_data_i( alu_data_exec )
    , .store_data_i(32'b0)
    , .inst_i( inst_exec_to_mem )
    , .valid_i( valid_exec_to_mem )
    , .flush_i( flush_wb_to_mem )
    , .do_write_i( do_write_exec_to_mem )
    , .ALU_data_o( alu_data_mem )
    , .mem_data_o( mem_data_mem_to_wb )
    , .wb_addr_o( wb_addr_mem_to_wb ) // write back address for register file
    , .valid_o( valid_mem_to_wb )
    , .flush_o( flush_mem_to_exec )
    , .load_o( load_mem_wb )
    , .do_write_o( do_write_mem_to_wb )
  );

  wire flush_wb_to_mem;
  wire alu_data_mem;
  wire mem_data_mem_to_wb;
  wire wb_addr_mem_to_wb;
  wire valid_mem_to_wb;
  wire load_mem_wb;
  wire do_write_mem_to_wb;

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

  // ************************************
  // ******** LOADING & STORING *********
  // ************************************
  reg [31:0] mem_addr;
  wire r_not_w;
  wire [31:0] mem_data_o;

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
