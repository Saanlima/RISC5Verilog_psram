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

// NW 20.9.2015

module Divider(
  input clk, ce, run, u,
  output stall,
  input [31:0] x, y,  // y > 0
  output [31:0] quot, rem);

reg [5:0] S;  // state
reg [63:0] RQ;
wire sign;
wire [31:0] x0, w0, w1;

assign stall = run & ~(S == 33);
assign sign = x[31] & u;
assign x0 = sign ? -x : x;
assign w0 = RQ[62: 31];
assign w1 = w0 - y;
assign quot = ~sign ? RQ[31:0] :
  (RQ[63:32] == 0) ? -RQ[31:0] : -RQ[31:0] - 1;
assign rem = ~sign ? RQ[63:32] :
  (RQ[63:32] == 0) ? 0 : y - RQ[63:32];

always @ (posedge(clk)) if(ce) begin
  RQ <= (S == 0) ? {32'b0, x0} : {(w1[31] ? w0 : w1), RQ[30:0], ~w1[31]};
  S <= run ? S+1 : 0;
end
endmodule
