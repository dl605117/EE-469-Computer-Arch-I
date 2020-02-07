module memory ( input clk_i
  , input [31:0] data_addr_i
  , input [31:0] data_i
  , input r_not_w_i
  , output [31:0] data_o);

  reg [7:0] memory [0:11];

  integer i;
  initial begin
    for ( i = 0; i < 12; i++ )
      { memory[data_addr_i], memory[data_addr_i+1], memory[data_addr_i+2], memory[data_addr_i+3] } <= i;
  end

  always @( posedge clk_i ) begin
    if ( r_not_w_i )
      data_o <= { memory[data_addr_i],  memory[data_addr_i+1], memory[data_addr_i+2], memory[data_addr_i+3] };
    else begin
      data_o <= data_o;
      { memory[data_addr_i],  memory[data_addr_i+1], memory[data_addr_i+2], memory[data_addr_i+3] } <= data_i;
    end
  end

endmodule
