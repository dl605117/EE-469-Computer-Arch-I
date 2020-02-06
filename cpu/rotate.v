module rotate ( input [3:0] rotate_i
        , input [7:0] immediate_i
        , output [31:0] operand2 );

  wire [39:0] number_rotate;
  assign number_rotate = { immediate_i, 24'b0, immediate_i };
  assign operand2 = number_rotate >> ( rotate_i * 2 );

endmodule
