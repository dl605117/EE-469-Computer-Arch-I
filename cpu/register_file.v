module register_file(
        input wire clk_i
      , input wire [3:0] a_addr_i
      , input wire [3:0] b_addr_i
      , input wire wr_en_i
      , input wire [3:0] wr_addr_i
      , input wire [31:0] data_i
      , output reg [31:0] a_o
      , output reg [31:0] b_o );

  reg [31:0] registers [15:0];

  integer i;
  initial begin
    for ( i = 0; i < 15; i=i+1 )
      registers[i] <= i;
  end

  always @(posedge clk_i) begin
    a_o <= registers[a_addr_i];
    b_o <= registers[b_addr_i];
    if ( wr_en_i ) begin
		//for ( i = 0; i < 16; i = i + 1 )
			//if ( i == wr_addr_i )
				registers[wr_addr_i] <= data_i;
			//else
				//registers[i] <= registers[i];
	end
		/*else
			for ( i = 0; i < 16; i = i + 1 )
				registers[i] <= registers[i];*/

  end

endmodule
