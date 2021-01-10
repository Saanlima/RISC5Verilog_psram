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

// NW 15.9.2015
module FPMultiplier(
  input clk, ce, run,
  input [31:0] x, y,
  output stall,
  output [31:0] z);

reg [4:0] S;  // state
reg [47:0] P; // product

wire sign;
wire [7:0] xe, ye;
wire [8:0] e0, e1;
wire [24:0] w1, z0;
wire [23:0] w0;

assign sign = x[31] ^ y[31];
assign xe = x[30:23];
assign ye = y[30:23];
assign e0 = xe + ye;
assign e1 = e0 - 127 + P[47];

assign stall = run & ~(S == 25);
assign w0 = P[0] ? {1'b1, y[22:0]} : 0;
assign w1 = {1'b0, P[47:24]} + {1'b0, w0};
assign z0 = P[47] ? P[47:23]+1 : P[46:22]+1; // round and normalize
assign z = (xe == 0) | (ye == 0) ? 0 :
   (~e1[8]) ? {sign, e1[7:0], z0[23:1]} :
   (~e1[7]) ? {sign, 8'b11111111, z0[23:1]} : 0;
always @ (posedge(clk)) if(ce) begin
    P <= (S == 0) ? {24'b0, 1'b1, x[22:0]} : {w1, P[23:1]};
    S <= run ? S+1 : 0;
end
endmodule
