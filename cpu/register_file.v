module register_file(
        input wire clk_i
      , input wire [3:0] a_addr_i
      , input wire [3:0] b_addr_i
      , input wire wr_en_i
      , input wire [3:0] wr_addr_i
      , input wire [31:0] data_i
      , input wire [31:0] pc
      , output reg [31:0] a_o
      , output reg [31:0] b_o );

  reg [31:0] registers [15:0];

  integer i;
  initial begin
    //registers[0] = 32'b0;
    //registers[1] = 32'b10000000_00000000_00000000_00000000;
    /*registers[2] = 32'b01111111_11111111_11111111_11111111;*/
    for ( i = 0; i < 15; i=i+1 )
      registers[i] <= i;
  end

  always @(posedge clk_i) begin
    if ( a_addr_i == 4'b1111 )
      a_o <= pc;
    else
      a_o <= registers[a_addr_i];
    if ( b_addr_i == 4'b1111 )
      b_o <= pc;
    else
      b_o <= registers[b_addr_i];
    if ( wr_en_i ) begin
      registers[wr_addr_i] <= data_i;
    end
  end

endmodule
