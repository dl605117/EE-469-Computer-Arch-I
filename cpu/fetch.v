module fetch (
    input clk_i
  , input branch
  , output [31:0] inst_o
);

  reg [31:0] pc_r, pc_n;
  wire pc_plus_4;
  wire pc_plus_8;
  wire pc_plus_12;

  assign pc_plus_4 = pc_r + 4;
  assign pc_plus_8 = pc_r + 8;
  assign pc_plus_12 = pc_r + 12;

  code_memory cm (  .clk(clk)
                  , .pc_i(pc_r)
                  , .inst(inst_o)
                  );

  initial pc_r = 0;

  always @(*) begin ////check PLS!!!!!
    if ( branch )   // Does Branch with Conditions
      pc_n = pc_plus_8 + { {6{branch_address[23]}}, branch_address, 2'b0 };
    else // Normal Increment
      pc_n = pc_plus_4;
    else if ( rd_address == 4'b1111 ) // if writing to register 15, needs to write to PC as well
      pc_n = data;
  end

  always @(posedge clk_i) pc_r <= pc_n;

endmodule
