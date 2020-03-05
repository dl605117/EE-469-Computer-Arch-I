module tb;

  /* Make a reset that pulses once. */
  reg reset = 0;
  initial begin
     $dumpfile("tb_TB.vcd");
     $dumpvars(0,tb);
     #50
     $stop;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

wire led, usbp,usbn,pu;
  top dut (
      .pin_clk(clk),

      .pin_usb_p(usbp),
      .pin_usb_n(usbn),
    .pin_pu(pu),

     .pin_led(led)

    );
endmodule // test
