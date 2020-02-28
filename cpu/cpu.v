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


  assign CPSR = { n_flag, z_flag, c_flag, v_flag, 22'b0, 5'b11111 };
  assign s_bit = inst[20];
  assign branch_address = inst[0+:24];
  assign rn_address = inst[16+:4];    // r2
  assign rm_address = inst[0+:4];     // r1
  assign opcode = inst[21+:4];
  assign instruction_codes = inst[25+:3];
  assign rotate = inst[8+:4];
  assign immediate = inst[0+:8];

  wire branch;
  wire [31:0] inst;

  shifter shifting (inst, r1_preshift, r1);

  fetch fetch_module ( .clk_i(clk), .branch(branch), .inst_o(inst) );

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
