module serialiser_10_to_1 (clk_x1, clk_x5, din, reset, serial);
  input clk_x1;
  input clk_x5;
  input reset;
  input [9:0]	din;
  output serial;

  wire shift1, shift2;
  reg ce_delay;

  OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),
	  .DATA_RATE_TQ   ("DDR"),
	  .DATA_WIDTH     (10),
	  .INIT_OQ        (1'b1),
	  .INIT_TQ        (1'b1),
	  .SERDES_MODE    ("MASTER"),
	  .SRVAL_OQ       (1'b0),
	  .SRVAL_TQ       (1'b0),
	  .TBYTE_CTL      ("FALSE"),
	  .TBYTE_SRC      ("FALSE"),
	  .TRISTATE_WIDTH (1))
  OSERDESE2_master(
    .OFB       (),
    .OQ        (serial),
    .SHIFTOUT1 (),
    .SHIFTOUT2 (),
    .TBYTEOUT  (),
    .TFB       (),
    .TQ        (),
    .CLK       (clk_x5),
    .CLKDIV    (clk_x1),
    .D1        (din[0]),
    .D2        (din[1]),
    .D3        (din[2]),
    .D4        (din[3]),
    .D5        (din[4]),
    .D6        (din[5]),
    .D7        (din[6]),
    .D8        (din[7]),
    .OCE       (ce_delay),
    .RST       (reset),
    .SHIFTIN1  (shift1),
    .SHIFTIN2  (shift2),
    .T1        (1'b0),
    .T2        (1'b0),
    .T3        (1'b0),
    .T4        (1'b0),
    .TBYTEIN   (1'b0),
    .TCE       (1'b0)
  );

  OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),
	  .DATA_RATE_TQ   ("DDR"),
	  .DATA_WIDTH     (10),
	  .INIT_OQ        (1'b1),
	  .INIT_TQ        (1'b1),
	  .SERDES_MODE    ("SLAVE"),
	  .SRVAL_OQ       (1'b0),
	  .SRVAL_TQ       (1'b0),
	  .TBYTE_CTL      ("FALSE"),
	  .TBYTE_SRC      ("FALSE"),
	  .TRISTATE_WIDTH (1))
  OSERDESE2_slave(
    .OFB       (),
    .OQ        (),
    .SHIFTOUT1 (shift1),
    .SHIFTOUT2 (shift2),
    .TBYTEOUT  (),
    .TFB       (),
    .TQ        (),
    .CLK       (clk_x5),
    .CLKDIV    (clk_x1),
    .D1        (1'b0),
    .D2        (1'b0),
    .D3        (din[8]),
    .D4        (din[9]),
    .D5        (1'b0),
    .D6        (1'b0),
    .D7        (1'b0),
    .D8        (1'b0),
    .OCE       (ce_delay),
    .RST       (reset),
    .SHIFTIN1  (1'b0),
    .SHIFTIN2  (1'b0),
    .T1        (1'b0),
    .T2        (1'b0),
    .T3        (1'b0),
    .T4        (1'b0),
    .TBYTEIN   (1'b0),
    .TCE       (1'b0)
  );

  always @ (posedge clk_x5 or posedge reset)
    if (reset)
      ce_delay <= 1'b0;
    else
      ce_delay <= 1'b1;

endmodule