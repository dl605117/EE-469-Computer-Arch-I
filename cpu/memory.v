module memory ( input clk_i
  , input [31:0] data_addr_i
  , input [31:0] data_i
  , input r_not_w_i
  , output [31:0] data_o);

  reg [7:0] memory [0:11];

  integer i;
  initial begin
    for ( i = 0; i < 12; i = i + 4 )
      { memory[i], memory[i+1], memory[i+2], memory[i+3] } <= 32'b0;
  end

assign data_o = { memory[data_addr_i],  memory[data_addr_i+1], memory[data_addr_i+2], memory[data_addr_i+3] };

  always @( posedge clk_i ) begin
    if ( ~r_not_w_i )
      { memory[data_addr_i],  memory[data_addr_i+1], memory[data_addr_i+2], memory[data_addr_i+3] } <= data_i;
  end

endmodule
