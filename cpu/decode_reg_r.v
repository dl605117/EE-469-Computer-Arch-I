module decode_reg_r (
    input wire clk_i
  , input wire reset_i
  , input wire [31:0] inst_i
  , input wire valid_i
  , input wire flush_i
  , input wire [31:0] wb_data_i
  , input wire [3:0] wb_addr_i
  , input wire wb_en_i
  , input wire stall_i
  , output reg valid_o
  , output wire [31:0] r1_o
  , output wire [31:0] r2_o
  , output reg [31:0] inst_o
  , output reg [3:0] r1_addr_o
  , output reg [3:0] r2_addr_o
  , output reg [3:0] rd_addr_o
  , output wire stall_o
  , output wire flush_o
);
  wire [3:0] rn_address;
  wire [3:0] rm_address;
  wire [3:0] rd_address;
  wire [3:0] r1_address;
  wire [3:0] r2_address;
  wire [2:0] instruction_codes;


  assign rn_address = stall_i ? inst_o[19:16] : inst_i[19:16];
  assign rm_address = stall_i ? inst_o[0+:4] : inst_i[0+:4];
  assign rd_address = stall_i ? inst_o[12+:4] : inst_i[12+:4];
  assign instruction_codes = stall_i ? inst_o[27:25] : inst_i[27:25];
  assign flush_o = flush_i;

  // ************************************
  // ***** Register File Addressing *****
  // ************************************
  assign r2_address = rn_address;
  assign r1_address = instruction_codes == 3'b010 ? rd_address : rm_address;
  /*always @(*) begin
    if ( instruction_codes == 3'b010 ) // LOAD and STORE
      r1_address = rd_address;
    else
      r1_address = rm_address;
  end*/

  register_file rf (  .clk_i(clk_i)
                    , .a_addr_i(r1_address)
                    , .b_addr_i(r2_address)
                    , .wr_en_i(wb_en_i)
                    , .wr_addr_i(wb_addr_i)
                    , .data_i(wb_data_i)
                    , .a_o(r1_o)
                    , .b_o(r2_o)
                    );

  always @(posedge clk_i) begin
    if ( reset_i ) begin
      valid_o <= 1'b0;
      inst_o <= 0;
    end
    else if ( stall_i ) begin
      valid_o <= valid_o;
      inst_o <= inst_o;
    end
    else begin
      if (flush_i)
        valid_o <= 0;
      else
        valid_o <= valid_i;
      inst_o <= inst_i;
    end
  end

  assign stall_o = stall_i;

  always @(posedge clk_i) begin
    if ( reset_i ) begin
      r1_addr_o <= 0;
      r2_addr_o <= 0;
      rd_addr_o <= 0;
    end
    else if ( stall_i ) begin
      r1_addr_o <= r1_addr_o;
      r2_addr_o <= r2_addr_o;
      rd_addr_o <= rd_addr_o;
    end
    else begin
      r1_addr_o <= r1_address;
      r2_addr_o <= r2_address;
      rd_addr_o <= rd_address;
    end
  end
endmodule
