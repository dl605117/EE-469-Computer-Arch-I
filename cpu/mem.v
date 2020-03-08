module mem (
    input wire clk_i
  , input wire reset_i
  , input wire [31:0] ALU_data_i
  , input wire [31:0] store_data_i
  , input wire [3:0] rd_addr_i
  , input wire [31:0] inst_i
  , input wire valid_i
  , input wire do_write_i
  , input wire flush_i
  , output reg [31:0] ALU_data_o
  , output wire [31:0] mem_data_o
  , output reg [3:0] wb_addr_o
  , output reg valid_o
  , output reg do_write_o
  , output wire flush_o
  , output reg load_o
  , output wire r_not_w
  , output wire [31:0] tester_reg
);

  /////////// wire/reg  ///////////
  //wire r_not_w;
  wire [3:0] wb_addr;
  wire s_bit;
  wire [2:0] instruction_codes;


  /////////// assign ///////////
  assign s_bit = inst_i[20];
  assign wb_addr = rd_addr_i;
  assign instruction_codes = inst_i[25+:3];
  assign r_not_w = ~(instruction_codes == 3'b010 & ~s_bit);
  assign flush_o = flush_i;

  memory mem (  .clk_i(clk_i)
              , .reset_i(reset_i)
              , .data_addr_i(ALU_data_i)
              , .data_i(store_data_i)
              , .r_not_w_i(r_not_w)
              , .valid_i(valid_i)
              , .data_o(mem_data_o)  //already pipeline
				  , .tester_reg( tester_reg )
              );

	/*reg [31:0] inst
	wire [31:0] mem_data;
	always @(*) begin
		mem_data
	end*/

  ////////// pipeline registers ///////////
  always @(posedge clk_i) begin
    if(reset_i) begin
      ALU_data_o <= 0;
      wb_addr_o <= 0;
      valid_o <= 0;
      load_o <= 0;
      do_write_o <= 0;
    end else begin
      ALU_data_o <= ALU_data_i;
      wb_addr_o <= wb_addr;
      valid_o <= valid_i;
      load_o <= (instruction_codes == 3'b010 && s_bit);
      do_write_o <= do_write_i;
    end
  end

endmodule
