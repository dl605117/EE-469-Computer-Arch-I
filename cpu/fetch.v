module fetch (
    input clk_i
  , input branch_i
  , input pc_wb_i
  , input data_i
  , input flush_i
  , output valid_o
  , output [31:0] inst_o
  , output [31:0] pc
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

  initial pc_r = 0;

  // ************************************
  // ********* Increment PC *************
  // ************************************
  always @(*) begin ////check PLS!!!!!
    if ( branch_i )   // Does Branch with Conditions
      pc_n = pc_plus_8 + { {6{branch_address[23]}}, branch_address, 2'b0 };
    else if ( pc_wb_i ) // if writing to register 15, needs to write to PC as well
      pc_n = data_i;
    else // Normal Increment
      pc_n = pc_plus_4;
  end

  always @(posedge clk_i) pc_r <= pc_n;
  assign pc = pc_r;

  // ************************************
  // *************** Valid **************
  // ************************************
  assign valid_o = flush_i ? 1'b0 : 1'b1;

endmodule
