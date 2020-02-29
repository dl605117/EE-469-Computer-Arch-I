module decode_reg_r (
    input clk_i
  , reset_i
  , input pc_i
  , input [31:0] inst_i
  , input valid_i
  , input flush_i
  , input [31:0] wb_data_i
  , input [3:0] wb_addr_i
  , input wb_en_i
  , input stall_i
  , output valid_o
  , output [31:0] r1_o
  , output [31:0] r2_o
  , output [31:0] inst_o
  , output [3:0] r1_addr_o
  , output [3:0] r2_addr_o
  , output [3:0] rd_addr_o
  , output stall_o
  , output flush_o
);
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] r1_address;
  wire [3:0] r2_address;

  assign rn_address = inst_i[16+:4];
  assign rm_address = inst_i[0+:4];
  assign rd_address = inst_i[12+:4];

  // ************************************
  // ***** Register File Addressing *****
  // ************************************
  assign r2_address = rn_address;
  always @(*) begin
    if ( instruction_codes == 3'b010 ) // LOAD and STORE
      r1_address = rd_address;
    else
      r1_address = rm_address;
  end

  register_file rf (  .clk_i(clk)
                    , .reset_i(reset_i)
                    , .r1_addr_i(r1_address)
                    , .r2_addr_i(r2_address)
                    , .wr_en_i(wb_en_i)
                    , .wr_addr_i(wb_addr_i)
                    , .data_i(wb_data_i)
                    , .pc(pc_i)
                    , .r1_o(r1_o)
                    , .r2_o(r2_o)
                    );

  always @(posedge clk_i) begin
    inst_o <= inst_i;
    if ( reset_i || flush_i )
      valid_o <= 1'b0;
    else
      valid_o <= valid_i;
  end

  always @(posedge clk_i) begin
    r1_addr_o <= r1_address;
    r2_addr_o <= r2_address;
    rd_addr_o <= rd_address;
    stall_o <= stall_i;
    flush_o <= flush_i
  end
endmodule
