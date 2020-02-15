module register_file( input clk_i
      , input [3:0] r1_addr_i
      , input [3:0] r2_addr_i
      , input wr_en_i
      , input [3:0] wr_addr_i
      , input [31:0] data_i
      , input [31:0] pc
      , output reg [31:0] r1_o, r2_o );

  reg [31:0] registers [15:0];

  integer i;
  initial begin
    registers[0] = 32'b01111111_11111111_11111111_11111111;
    registers[1] = 32'b01111111_11111111_11111111_11111111;
    registers[2] = 32'b01111111_11111111_11111111_11111111;
    for ( i = 3; i < 16; i++ )
      registers[i] <= i;
  end

  always @(posedge clk_i) begin
    if ( r1_addr_i == 4'b1111 )
      r1_o <= pc;
    else
      r1_o <= registers[r1_addr_i];
    if ( r2_addr_i == 4'b1111 )
      r2_o <= pc;
    else
      r2_o <= registers[r2_addr_i];
    if ( wr_en_i ) begin
      registers[wr_addr_i] <= data_i;
    end
  end

endmodule
