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

// NW 16.9.2016

module FPDivider(
    input clk, ce, run,
    input [31:0] x,
    input [31:0] y,
    output stall,
    output [31:0] z);

reg [4:0] S;  // state
reg [23:0] R;
reg [25:0] Q;

wire sign;
wire [7:0] xe, ye;
wire [8:0] e0, e1;
wire [24:0] r0, r1, d;
wire [25:0] q0;
wire [24:0] z0, z1;

assign sign = x[31]^y[31];
assign xe = x[30:23];
assign ye = y[30:23];
assign e0 = {1'b0, xe} - {1'b0, ye};
assign e1 = e0 + 126 + Q[25];
assign stall = run & ~(S == 26);

assign r0 = (S == 0) ? {2'b01, x[22:0]} : {R, 1'b0};
assign r1 = d[24] ? r0 : d;
assign d = r0 - {2'b01, y[22:0]};
assign q0 = (S == 0) ? 0 : Q;

assign z0 = Q[25] ? Q[25:1] : Q[24:0];
assign z1 = z0 + 1;
assign z = (xe == 0) ? 0 :
  (ye == 0) ? {sign, 8'b11111111, 23'b0} :  // div by 0
  (~e1[8]) ? {sign, e1[7:0], z0[23:1]} :
  (~e1[7]) ? {sign, 8'b11111111, z0[23:1]} : 0; // NaN

always @ (posedge(clk)) if(ce) begin
  R <= r1[23:0];
  Q <= {q0[24:0], ~d[24]};
  S <= run ? S+1 : 0;
end
endmodule
