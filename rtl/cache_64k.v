//////////////////////////////////////////////////////////////////////////////////
//
// Filename: cache_64k.v
// Description: 2-way, 512-set cache with 64 byte cache lines
// Version 1.1
// Creation date: Jan 9, 2021
//
// Author: Magnus Karlsson 
// e-mail: magnus@saanlima.com
//
// Loosely based on cache_controller.v written by Nicolae Dumitrache
//
/////////////////////////////////////////////////////////////////////////////////
// 
// Copyright (C) 2020 Magnus Karlsson
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

 
module cache_64k(
    // cpu interface
    input clk,  
    input [23:0] addr,       // cpu address
    output [31:0] dout,      // read data to cpu
    input [31:0] din,        // write data from cpu
    input mreq,              // memory accress request
    input [3:0] wmask,       // memory byte write enable
    output ce,               // cpu clock enable signal (cpu stall if 0)
    // memory controller interface
    input mem_clk,           // memory controller clock
    input [127:0] mem_din,   // read data from memory
    output [127:0] mem_dout, // write data to memory
    output reg mem_rd,       // memory read request
    output reg mem_wr,       // memory write request
    output reg [23:6] waddr, // memory write address
    output reg [23:6] raddr, // memory read address
    input cache_wr,          // cache write
    input cache_rd,          // cache read
    input [1:0] cache_addr,  // cache address
    input rd_busy,           // memory controller busy read
    input wr_busy            // memory controller busy write
  );

  reg [2:0] STATE;
  reg [8:0] tag0 [0:511] = 
    {9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0,
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0,
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0,
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 
     9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0, 9'd0} ;
  reg [8:0] tag1 [0:511] = 
    {9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1,
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1,
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1,
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 
     9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1, 9'd1} ;
  reg [511:0] dirty0 = 512'b0;
  reg [511:0] dirty1 = 512'b0;
  reg [511:0] mru = 512'b0;
  wire [8:0] index;
  wire hit0, hit1, hit;
  wire st0;
  wire wr;
  reg rd_busy_sync, wr_busy_sync;
  
  assign ce = st0 & (~mreq | hit);
  assign index = addr[14:6];
  assign hit0 = (tag0[index] == addr[23:15]);
  assign hit1 = (tag1[index] == addr[23:15]);
  assign hit = hit0 | hit1;
  assign st0 = (STATE == 3'b000);
  assign wr = |wmask;

  always @(posedge clk) begin
    rd_busy_sync <= rd_busy;
    wr_busy_sync <= wr_busy;
    raddr <= addr[23:6];
    case(STATE)
      3'b000: begin
        mem_wr <= 1'b0;
        mem_rd <= 1'b0;
        if(mreq & hit0) begin // cache hit0
          mru[index] <= 1'b0;
          if(wr) dirty0[index] <= 1'b1;
        end else if(mreq & hit1) begin // cache hit1
          mru[index] <= 1'b1;
          if(wr) dirty1[index] <= 1'b1;
        end
        if(mreq && !hit) begin  // cache miss
          if(mru[index] == 1'b1) begin
            waddr <= {tag0[index], addr[14:6]}; 
            tag0[index] <= addr[23:15];
            if (dirty0[index]) begin
              mem_wr <= 1'b1;
              dirty0[index] <= 1'b0;
              STATE <= 3'b011;
            end else begin
              mem_rd <= 1'b1;
              STATE <= 3'b111;
            end
          end else begin
            waddr <= {tag1[index], addr[14:6]}; 
            tag1[index] <= addr[23:15];
            if (dirty1[index]) begin
              mem_wr <= 1'b1;
              dirty1[index] <= 1'b0;
              STATE <= 3'b011;
            end else begin
              mem_rd <= 1'b1;
              STATE <= 3'b111;
            end
          end
        end
      end
      3'b011: begin  // write cache to memory
        if(wr_busy_sync) begin
          mem_wr <= 1'b0;
          mem_rd <= 1'b1;
          STATE <= 3'b111;
        end
      end
      3'b111: begin // read cache from memory
        if(rd_busy_sync) begin
          mem_rd <= 1'b0;
          STATE <= 3'b101;
        end
      end
      3'b101: begin // wait for memory read to finish
        if(~rd_busy_sync)
          STATE <= 3'b000;
      end
    endcase
  end

  cache_mem mem
  (
    .clka(~clk),
    .ena(mreq & hit & st0),
    .wea({4{mreq & hit & st0 & wr}} & wmask),
    .addra({~hit0, addr[14:2]}),
    .dina(din),
    .douta(dout),
    .clkb(mem_clk),
    .enb(cache_wr | cache_rd),
    .web({16{cache_wr}}),
    .addrb({~mru[raddr[14:6]], raddr[14:6], cache_addr}),
    .dinb(mem_din),
    .doutb(mem_dout)
  );

endmodule

module cache_mem (
    input wire clka,
    input wire ena,
    input wire [3:0] wea,
    input wire [13:0] addra,
    input wire [31:0] dina,
    output wire [31:0] douta,
    input wire clkb,
    input wire enb,
    input wire [15:0] web,
    input wire [11:0] addrb,
    input wire [127:0] dinb,
    output wire [127:0] doutb
  );

  wire [127:0] dina_64;
  wire [127:0] douta_64;
  wire [15:0] wea_64;
  wire [11:0] addra_64;

  assign dina_64 = {4{dina}};
  assign addra_64 = addra[13:2];
  assign wea_64 = addra[1:0] == 2'b00 ? {12'b0, wea} :
                   addra[1:0] == 2'b01 ? {8'b0, wea, 4'b0} :
                   addra[1:0] == 2'b10 ? {4'b0, wea, 8'b0} : {wea, 12'b0};
  assign douta = addra[1:0] == 2'b00 ? douta_64[31:0] :
                 addra[1:0] == 2'b01 ? douta_64[63:32] :
                 addra[1:0] == 2'b10 ? douta_64[95:64] : douta_64[127:96];
                 
  bram_tdp byte0 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[0]),
    .a_addr    (addra_64),
    .a_din     (dina_64[7:0]),
    .a_dout    (douta_64[7:0]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[0]),
    .b_addr    (addrb),
    .b_din     (dinb[7:0]),
    .b_dout    (doutb[7:0])
  );

  bram_tdp byte1 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[1]),
    .a_addr    (addra_64),
    .a_din     (dina_64[15:8]),
    .a_dout    (douta_64[15:8]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[1]),
    .b_addr    (addrb),
    .b_din     (dinb[15:8]),
    .b_dout    (doutb[15:8])
  );

  bram_tdp byte2 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[2]),
    .a_addr    (addra_64),
    .a_din     (dina_64[23:16]),
    .a_dout    (douta_64[23:16]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[2]),
    .b_addr    (addrb),
    .b_din     (dinb[23:16]),
    .b_dout    (doutb[23:16])
  );

  bram_tdp byte3 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[3]),
    .a_addr    (addra_64),
    .a_din     (dina_64[31:24]),
    .a_dout    (douta_64[31:24]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[3]),
    .b_addr    (addrb),
    .b_din     (dinb[31:24]),
    .b_dout    (doutb[31:24])
  );

  bram_tdp byte4 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[4]),
    .a_addr    (addra_64),
    .a_din     (dina_64[39:32]),
    .a_dout    (douta_64[39:32]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[4]),
    .b_addr    (addrb),
    .b_din     (dinb[39:32]),
    .b_dout    (doutb[39:32])
  );

  bram_tdp byte5 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[5]),
    .a_addr    (addra_64),
    .a_din     (dina_64[47:40]),
    .a_dout    (douta_64[47:40]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[5]),
    .b_addr    (addrb),
    .b_din     (dinb[47:40]),
    .b_dout    (doutb[47:40])
  );

  bram_tdp byte6 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[6]),
    .a_addr    (addra_64),
    .a_din     (dina_64[55:48]),
    .a_dout    (douta_64[55:48]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[6]),
    .b_addr    (addrb),
    .b_din     (dinb[55:48]),
    .b_dout    (doutb[55:48])
  );

  bram_tdp byte7 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[7]),
    .a_addr    (addra_64),
    .a_din     (dina_64[63:56]),
    .a_dout    (douta_64[63:56]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[7]),
    .b_addr    (addrb),
    .b_din     (dinb[63:56]),
    .b_dout    (doutb[63:56])
  );
  bram_tdp byte8 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[8]),
    .a_addr    (addra_64),
    .a_din     (dina_64[71:64]),
    .a_dout    (douta_64[71:64]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[8]),
    .b_addr    (addrb),
    .b_din     (dinb[71:64]),
    .b_dout    (doutb[71:64])
  );

  bram_tdp byte9 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[9]),
    .a_addr    (addra_64),
    .a_din     (dina_64[79:72]),
    .a_dout    (douta_64[79:72]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[9]),
    .b_addr    (addrb),
    .b_din     (dinb[79:72]),
    .b_dout    (doutb[79:72])
  );

  bram_tdp byte10 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[10]),
    .a_addr    (addra_64),
    .a_din     (dina_64[87:80]),
    .a_dout    (douta_64[87:80]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[10]),
    .b_addr    (addrb),
    .b_din     (dinb[87:80]),
    .b_dout    (doutb[87:80])
  );

  bram_tdp byte11 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[11]),
    .a_addr    (addra_64),
    .a_din     (dina_64[95:88]),
    .a_dout    (douta_64[95:88]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[11]),
    .b_addr    (addrb),
    .b_din     (dinb[95:88]),
    .b_dout    (doutb[95:88])
  );
  bram_tdp byte12 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[12]),
    .a_addr    (addra_64),
    .a_din     (dina_64[103:96]),
    .a_dout    (douta_64[103:96]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[12]),
    .b_addr    (addrb),
    .b_din     (dinb[103:96]),
    .b_dout    (doutb[103:96])
  );

  bram_tdp byte13 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[13]),
    .a_addr    (addra_64),
    .a_din     (dina_64[111:104]),
    .a_dout    (douta_64[111:104]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[13]),
    .b_addr    (addrb),
    .b_din     (dinb[111:104]),
    .b_dout    (doutb[111:104])
  );

  bram_tdp byte14 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[14]),
    .a_addr    (addra_64),
    .a_din     (dina_64[119:112]),
    .a_dout    (douta_64[119:112]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[14]),
    .b_addr    (addrb),
    .b_din     (dinb[119:112]),
    .b_dout    (doutb[119:112])
  );

  bram_tdp byte15 (
    .a_clk     (clka),
    .a_en      (ena),
    .a_wr      (wea_64[15]),
    .a_addr    (addra_64),
    .a_din     (dina_64[127:120]),
    .a_dout    (douta_64[127:120]),
    .b_clk     (clkb),
    .b_en      (enb),
    .b_wr      (web[15]),
    .b_addr    (addrb),
    .b_din     (dinb[127:120]),
    .b_dout    (doutb[127:120])
  );

endmodule


module bram_tdp #(
    parameter DATA = 8,
    parameter ADDR = 12
  ) (
    // Port A
    input   wire                a_clk,
    input   wire                a_en,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_en,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
  );
   
  // Shared memory
  reg [DATA-1:0] mem [(2**ADDR)-1:0];
   
  // Port A
  always @(posedge a_clk) begin
    if (a_en) begin
      a_dout <= mem[a_addr];
      if (a_wr) begin
        a_dout <= a_din;
        mem[a_addr] <= a_din;
      end
    end
  end
   
  // Port B
  always @(posedge b_clk) begin
    if (b_en) begin
      b_dout <= mem[b_addr];
      if (b_wr) begin
        b_dout <= b_din;
        mem[b_addr] <= b_din;
      end
    end
  end
 
endmodule