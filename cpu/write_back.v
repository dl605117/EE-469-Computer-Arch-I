module write_back (
    input [31:0] mem_data_i
  , input [31:0] ALU_data_i
  , input [31:0] inst_i
  , input load_i
  , input valid_i
  , input wb_i
  , input [3:0] wb_addr_i
  , output wr_en_o
  , output [31:0] wb_data_o
  , output [3:0] wb_addr_o
)
  assign wb_addr_o = wb_addr_i;
  assign wr_en_o = valid_i & wb_i; ///check
  assign wb_data_o = load_i ? mem_data_i : ALU_data_i;
endmodule
