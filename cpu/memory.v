module memory ( input clk_i
  , input wire reset_i
  , input wire [31:0] data_addr_i
  , input wire [31:0] data_i
  , input wire r_not_w_i
  , input wire valid_i
  , output reg [31:0] data_o
  , output [31:0] teser_reg
  );

  reg [31:0] memory [0:11];
  

  integer i;
  initial begin
    for ( i = 0; i < 12; i = i + 1 )
      memory[i] <= 32'b0;
  end

  always @( posedge clk_i ) begin
    if ( reset_i ) begin
      data_o <= 0;
      for ( i = 0; i < 12; i = i + 1 )
        memory[i] <= 32'b0;
    end
    else if(valid_i) begin
      
      if ( r_not_w_i )
			data_o <= memory[data_addr_i];
		else begin
			memory[data_addr_i] <= data_i;
			data_o <= 32'b0;
		end
    end
	 else
		data_o <= 32'b0;
  end
  
	assign tester_reg = memory[0];
	
endmodule
