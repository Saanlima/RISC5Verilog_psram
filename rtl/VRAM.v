//////////////////////////////////////////////////////////////////////////////////
//
// Filename: VRAM.v
// Description: Video frame buffer in BRAM
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

module VRAM (
  input clka,
  input [14:0] adra,
  input [3:0] bea,
  input wea,
  input [31:0] wda,
  output [31:0] rda,
  input clkb,
  input [14:0] adrb,
  output [31:0] rdb);
  
  wire [7:0] rda_0, rda_1, rda_2, rda_3;
  wire [7:0] viddata_0, viddata_1, viddata_2, viddata_3;

  VRAM8 vram8_0(.clka(clka), .adra(adra), .wea(wea & bea[0]),
  .wda(wda[7:0]), .rda(rda_0), .clkb(clkb), .adrb(adrb),
  .rdb(viddata_0));

  VRAM8 vram8_1(.clka(clka), .adra(adra), .wea(wea & bea[1]),
  .wda(wda[15:8]), .rda(rda_1), .clkb(clkb), .adrb(adrb),
  .rdb(viddata_1));

  VRAM8 vram8_2(.clka(clka), .adra(adra), .wea(wea & bea[2]),
  .wda(wda[23:16]), .rda(rda_2), .clkb(clkb), .adrb(adrb),
  .rdb(viddata_2));

  VRAM8 vram8_3(.clka(clka), .adra(adra), .wea(wea & bea[3]),
  .wda(wda[31:24]), .rda(rda_3), .clkb(clkb), .adrb(adrb),
  .rdb(viddata_3));

  assign rda = {rda_3, rda_2, rda_1, rda_0};
  assign rdb = {viddata_3, viddata_2, viddata_1, viddata_0};

endmodule


module VRAM8 (
  input clka,
  input [14:0] adra,
  input wea,
  input [7:0] wda,
  output reg [7:0] rda,
  input clkb,
  input [14:0] adrb,
  output reg [7:0] rdb);

  reg [7:0] ram [24575:0];

  // Port A
  always @(posedge clka) begin
    rda <= ram[adra];
    if(wea) begin
      rda <= wda;
      ram[adra] <= wda;
    end
  end

  // Port B
  always @(posedge clkb) begin
    rdb <= ram[adrb];
  end
 
endmodule
