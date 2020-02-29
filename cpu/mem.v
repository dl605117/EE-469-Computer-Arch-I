module mem (
    input clk_i
  , input reset_i
  , input [31:0] ALU_data_i
  , input [31:0] store_data_i
  , input [31:0] inst_i
  , input valid_i
  , input do_write_i
  , input flush_i
  , output [31:0] ALU_data_o
  , output [31:0] mem_data_o
  , output [3:0] wb_addr_o
  , output valid_o
  , output do_write_o
  , output flush_o
  , output load_o
);

  /////////// wire/reg  ///////////
  wire r_not_w;
  wire U_bit;


  /////////// assign ///////////
  assign wb_addr = inst_i[15:12];
  assign instruction_codes = inst_i[25+:3];
  assign s_bit = inst[20];
  assign r_not_w = ~(instruction_codes == 3'b010 && ~s_bit);
  assign U_bit = inst[23]; // 1 = add, 0 = subtract from base
  assign flush_o = flush_i;

  memory mem (  .clk_i(clk)
              , .reset_i(reset_i)
              , .data_addr_i(ALU_data_i)
              , .data_i(store_data_i)
              , .r_not_w_i(r_not_w)
              , .valid_i(valid_i)
              , .data_o(mem_data_o)  //already pipeline
              );

  ////////// pipeline registers ///////////
  always @(posedge clk) begin
    if(reset_i) begin
      ALU_data_o <= 0;
      wb_addr_o <= 0;
      valid_o <= 0;
      load_o <= 0;
    end else begin
      ALU_data_o <= ALU_data_i;
      wb_addr_o <= wb_addr;
      valid_o <= valid_i
      load_o <= (instruction_codes == 3'b010 && s_bit);
    end
  end
endmodule
