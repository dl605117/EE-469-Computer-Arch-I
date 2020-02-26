module fetch (
    input clk
  , input flush //change instruction to NOP
  , input stall_i
  , output [31:0] inst_o
  , output valid_o
  , output pc_o
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

  always @(posedge clk) begin
    pc_o <= pc_r;
    if(stall_i)
      pc_r <= pc_r;
    else begin
      pc_r <= pc_n;
      if (flush)
        valid_o <= 0;
      else
        valid_o <= 1;
    end
  end

endmodule
