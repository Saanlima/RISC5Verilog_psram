`timescale 1ns / 1ps   

/*Project Oberon, Revised Edition 2013

Book copyright (C)2013 Niklaus Wirth and Juerg Gutknecht;
software copyright (C)2013 Niklaus Wirth (NW), Juerg Gutknecht (JG), Paul
Reed (PR/PDR).

Permission to use, copy, modify, and/or distribute this software and its
accompanying documentation (the "Software") for any purpose with or
without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL WARRANTIES
WITH REGARD TO THE SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY, FITNESS AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, SPECIAL, DIRECT, INDIRECT, OR
CONSEQUENTIAL DAMAGES OR ANY DAMAGES OR LIABILITY WHATSOEVER, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE DEALINGS IN OR USE OR PERFORMANCE OF THE SOFTWARE.*/

// NW 14.9.2015

module Multiplier(
  input clk, ce, run, u,
  output stall,
  input [31:0] x, y,
  output [63:0] z);

reg [5:0] S;    // state
reg [63:0] P;   // product
wire [31:0] w0;
wire [32:0] w1;

assign stall = run & ~(S == 33);
assign w0 = P[0] ? y : 0;
assign w1 = (S == 32) & u ? {P[63], P[63:32]} - {w0[31], w0} :
       {P[63], P[63:32]} + {w0[31], w0};
assign z = P;

always @ (posedge(clk)) if(ce) begin
  P <= (S == 0) ? {32'b0, x} : {w1[32:0], P[31:1]};
  S <= run ? S+1 : 0;
end

endmodule
