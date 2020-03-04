module fetch (
    input wire clk_i
  , input wire reset_i
  , input wire branch_i
  , input wire branch_address_i
  , input wire [31:0] pc_wb_i
  , input wire [31:0] data_i
  , input wire flush_i
  , input wire stall_i
  , output reg valid_o
  , output reg [31:0] inst_o
  , output wire [31:0] pc
);
  reg [31:0] pc_r, pc_n;
  wire pc_plus_4;
  wire pc_plus_8;
  wire pc_plus_12;

  assign pc_plus_4 = pc_r + 4;
  assign pc_plus_8 = pc_r + 8;
  assign pc_plus_12 = pc_r + 12;

  code_memory cm (  .clk(clk_i)
                  , .pc_i(pc_r)
                  , .inst(inst_o)
                  );

  initial pc_r = 32'b0;

  // ************************************
  // ********* Increment PC *************
  // ************************************
  always @(*) begin ////check PLS!!!!!
    if ( stall_i )
      pc_n = pc_r;
    else if ( branch_i )   // Does Branch with Conditions
      pc_n = pc_r + 8 + { {6{branch_address_i[23]}}, branch_address_i, 2'b0 };
    else if ( pc_wb_i ) // if writing to register 15, needs to write to PC as well
      pc_n = data_i;
    else if ( pc_r >= 100 )// Normal Increment
      pc_n = 0;
    else
      pc_n = pc_r + 4;
  end

  always @(posedge clk_i)
    if ( reset_i )
      pc_r <= 32'b0;
    else
      pc_r <= pc_n;

  assign pc = pc_r;

  // ************************************
  // *************** Valid **************
  // ************************************
  always @(*)
    if ( reset_i || flush_i )
      valid_o = 1'b0;
    else
      valid_o = 1'b1;

endmodule
