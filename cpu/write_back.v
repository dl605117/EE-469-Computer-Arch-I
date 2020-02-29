module write_back (
    input [31:0] mem_data_i
  , input [31:0] ALU_data_i
  , input load_i
  , input valid_i
  , input do_write_i
  , input [3:0] wb_addr_i
  , output wb_en_o
  , output [31:0] wb_data_o
  , output [3:0] wb_addr_o
  , output pc_wb_o
  , output flush_o
);
  assign wb_addr_o = wb_addr_i;
  assign wb_en_o = valid_i & do_write_i; ///check
  assign wb_data_o = load_i ? mem_data_i : ALU_data_i;
  assign pc_wb_o = wb_addr_i == 4'b1111 && wb_en_o;
  assign flush_o = pc_wb_o;
endmodule
