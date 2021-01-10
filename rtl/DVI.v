//////////////////////////////////////////////////////////////////////////////////
//
// Filename: DVI.v
// Description: VGA to DVI
// Creation date: Jan 9, 2021
//
// Author: Magnus Karlsson 
// e-mail: magnus@saanlima.com
//
//
/////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (C) 2021 Magnus Karlsson
// 
// This source file may be used and distributed without 
// restriction provided that this copyright statement is not 
// removed from the file and that any derivative work contains 
// the original copyright notice and the associated disclaimer.
// 
// This source file is free software; you can redistribute it 
// and/or modify it under the terms of the GNU Lesser General 
// Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any 
// later version. 
// 
// This source is distributed in the hope that it will be 
// useful, but WITHOUT ANY WARRANTY; without even the implied 
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
// PURPOSE. See the GNU Lesser General Public License for more 
// details. 
// 
// You should have received a copy of the GNU Lesser General 
// Public License along with this source; if not, download it 
// from https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html
// 
///////////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

module DVI (
  input  wire reset,
  input  wire pll_reset,
  input  wire clkx1,
  input  wire clkx5,
  input  wire [7:0] blue_in,
  input  wire [7:0] green_in,
  input  wire [7:0] red_in,
  input  wire       hsync,
  input  wire       vsync,
  input  wire       vde,
  output wire [3:0] TMDS,
  output wire [3:0] TMDSB
);

wire [9:0] red;
wire [9:0] green;
wire [9:0] blue;
wire [2:0] tmdsint;

encode encb (
  .clkin  (clkx1),
  .rstin  (reset),
  .din    (blue_in),
  .c0     (hsync),
  .c1     (vsync),
  .de     (vde),
  .dout   (blue)
);

encode encg (
  .clkin  (clkx1),
  .rstin  (reset),
  .din    (green_in),
  .c0     (1'b0),
  .c1     (1'b0),
  .de     (vde),
  .dout   (green)
);

encode encr (
  .clkin  (clkx1),
  .rstin  (reset),
  .din    (red_in),
  .c0     (1'b0),
  .c1     (1'b0),
  .de     (vde),
  .dout   (red)
);

serialiser_10_to_1 oserdes0 (
  .clk_x1   (clkx1),
  .clk_x5   (clkx5),
  .reset    (pll_reset),
  .din      (blue),
  .serial   (tmdsint[0])
);

serialiser_10_to_1 oserdes1 (
  .clk_x1   (clkx1),
  .clk_x5   (clkx5),
  .reset    (pll_reset),
  .din      (green),
  .serial   (tmdsint[1])
);

serialiser_10_to_1 oserdes2 (
  .clk_x1   (clkx1),
  .clk_x5   (clkx5),
  .reset    (pll_reset),
  .din      (red),
  .serial   (tmdsint[2])
);

serialiser_10_to_1 clkout (
  .clk_x1   (clkx1),
  .clk_x5   (clkx5),
  .reset    (pll_reset),
  .din      (10'b0000011111),
  .serial   (tmdsclk)
);
  
OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0]));
OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1]));
OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2]));
OBUFDS TMDS3 (.I(tmdsclk),    .O(TMDS[3]), .OB(TMDSB[3]));

endmodule
