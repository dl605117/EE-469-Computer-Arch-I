module fetch (
    input clk
  , output [31:0] inst_o
);

  reg [31:0] pc_r, pc_n;

  code_memory cm (  .clk(clk)
                  , .pc_i(pc_r)
                  , .inst(inst_o)
                  );

  initial pc_r = 0;

  always @(*) begin ////check PLS!!!!!
    if ( instruction_codes == 3'b101 && cond_met )   // Does Branch with Conditions
      pc_n = pc_r + 8 + { {6{branch_address[23]}}, branch_address, 2'b0 };
    else
      pc_n = pc_r + 4;
    else if ( pc_state_r == exec_mem && rd_address == 4'b1111 ) //check PLS!!!!!
      pc_n = data;
  end

  always @(posedge clk) pc_r <= pc_n;

endmodule
