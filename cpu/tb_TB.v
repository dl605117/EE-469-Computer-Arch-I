module tb;

  /* Make a reset that pulses once. */
  reg reset = 0;
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,tb);

     # 17 reset = 1;
     # 11 reset = 0;
     # 29 reset = 1;
     # 5  reset =0;
     # 513 $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;


  wire [7:0] debug_port1, debug_port2, debug_port3, debug_port4, debug_port5, debug_port6, debug_port7;
  wire led;
  cpu dut (clk, reset, led,
  debug_port1,
  debug_port2,
  debug_port3,
  debug_port4,
  debug_port5,
  debug_port6,
  debug_port7
  );
endmodule // test
