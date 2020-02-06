module register_file( input clk_i
      , input [3:0] r1_addr_i
      , input [3:0] r2_addr_i
      , input wr_en_i
      , input [3:0] wr_addr_i
      , input [31:0] data_i
      , output reg [31:0] r1_o, r2_o );

  reg [31:0] registers [15:0];

  integer i;
  initial begin
    for ( i = 0; i < 16; i++ )
      registers[i] <= i;
  end

  always @(posedge clk_i) begin
    r1_o <= registers[r1_addr_i];
    r2_o <= registers[r2_addr_i];
    if ( wr_en_i ) begin
      registers[wr_addr_i] <= data_i;
    end
  end

endmodule
