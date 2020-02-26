module mem (
   input clk
  , input [31:0] ALU_data_i
  , input [31:0] inst_i
  , input valid_i
  , output [31:0] ALU_data_o
  , output [31:0] mem_data_o
  , output [3:0] wb_addr_o
  , output valid_o
  , output wb_o
)
  assign wb_addr = inst_i[15:12];
  assign instruction_codes = inst_i[25+:3];
  assign s_bit = inst[20];
  assign r_not_w = ~(instruction_codes == 3'b010 && ~s_bit);

  memory mem (  .clk_i(clk)
              , .data_addr_i(mem_addr)
              , .data_i(ALU_data_i)
              , .r_not_w_i(r_not_w)
              , .valid_i(valid_i)
              , .data_o(mem_data_o)
              );

  // pipeline registers
  always @(posedge clk) begin
    ALU_data_o <= ALU_data_i;
    wb_addr_o <= wb_addr;
    valid_o <= valid_i
    load_i <= r_not_w;
  end
endmodule
