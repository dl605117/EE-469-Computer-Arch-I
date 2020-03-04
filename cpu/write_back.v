module write_back (
    input wire [31:0] mem_data_i
  , input wire [31:0] ALU_data_i
  , input wire load_i
  , input wire valid_i
  , input wire do_write_i
  , input wire [3:0] wb_addr_i
  , output wire wb_en_o
  , output wire [31:0] wb_data_o
  , output wire [3:0] wb_addr_o
  , output wire [31:0] pc_wb_o
  , output wire flush_o
);
  assign wb_addr_o = wb_addr_i;
  assign wb_en_o = valid_i & do_write_i; ///check
  assign wb_data_o = load_i ? mem_data_i : ALU_data_i;
  assign pc_wb_o = wb_addr_i == 4'b1111 && wb_en_o;
  assign flush_o = pc_wb_o;
endmodule
