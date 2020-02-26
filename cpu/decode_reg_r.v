module decode_reg_r (
    input clk_i
  , input pc_i
  , input [31:0] inst_i
  , input valid_i
  , input flush
  , input [31:0] wb_data_i
  , input [3:0] wb_addr_i
  , input wb_en_i
  , output valid_o
  , output [31:0] r1_o
  , output [31:0] r2_o
  , output [31:0] inst_o
)
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] r1_address;
  wire [3:0] r2_address;

  assign rn_address = inst_i[16+:4];
  assign rm_address = inst_i[0+:4];

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

  

  always @(posedge clk_i) begin
    inst_o <= inst_i;
    if(flush)
      valid_o <= 0;
    else
      valid_o <= valid_i;
  end

endmodule
