//////////////////////////////////////////////////////////////////////////////////
//
// Filename: PSRAM.v
// Description: Memory controller for QSPI PSRAM
//              Reading and writing 64 byte cache lines
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

module PSRAM (
  input mem_clk,
  input reset,
  input mem_rd,                   // memory read request
  input mem_wr,                   // memory write request
  input [23:6] waddr,             // memory write address
  input [23:6] raddr,             // memory read address
  input [127:0] cache_rdata,      // write data to memory
  output reg [127:0] cache_wdata, // read data from memory
  output reg cache_en,            // cache enable
  output reg cache_we,            // cache write
  output reg [1:0] cache_addr,    // cache address
  output reg rd_busy,             // memory controller busy read
  output reg wr_busy,             // memory controller busy write
  output reg psram_ce,
  output psram_sclk,
  inout psram_sio0,
  inout psram_sio1,
  inout psram_sio2,
  inout psram_sio3,
  output reg [63:0] id_reg
);

reg mem_wr_sync;
reg mem_rd_sync;
reg [4:0] state, next_state;
reg [1:0] next_cache_addr;
reg next_cache_en;
reg next_cache_we;
reg [127:0] next_cache_wdata;
reg next_wr_busy;
reg next_rd_busy;
reg [13:0] pscnt, next_pscnt;
reg next_psram_ce;
reg psram_oe, next_psram_oe;
reg [31:0] psram_data, next_psram_data;
reg [6:0] psram_bitcnt, next_psram_bitcnt;
reg [3:0] high_nybble, next_high_nybble;
reg [63:0] next_id_reg;

wire [3:0] psram_out;
wire [3:0] psram_in;


IOBUF buf_data0 (.IO(psram_sio0), .O(psram_in[0]), .I(psram_out[0]), .T(psram_oe));
IOBUF buf_data1 (.IO(psram_sio1), .O(psram_in[1]), .I(psram_out[1]), .T(psram_oe));
IOBUF buf_data2 (.IO(psram_sio2), .O(psram_in[2]), .I(psram_out[2]), .T(psram_oe));
IOBUF buf_data3 (.IO(psram_sio3), .O(psram_in[3]), .I(psram_out[3]), .T(psram_oe));

ODDR #(
  .DDR_CLK_EDGE("SAME_EDGE"),
  .INIT(1'b0),
  .SRTYPE("SYNC")
) clock_forward_inst (
  .Q(psram_sclk),
  .C(mem_clk),
  .CE(1'b1),
  .D1(1'b1),
  .D2(1'b0),
  .R(1'b0),
  .S(1'b0)
);

parameter [4:0]
  STARTUP = 5'd0,
  INIT1 = 5'd1,
  INIT2 = 5'd2,
  INIT3 = 5'd3,
  INIT4 = 5'd4,
  INIT5 = 5'd5,
  INIT6 = 5'd6,
  INIT7 = 5'd7,
  INIT8 = 5'd8,
  INIT9 = 5'd9,
  INIT10 = 5'd10,
  INIT11 = 5'd11,
  INIT12 = 5'd12,
  INIT13 = 5'd13,
  INIT14 = 5'd14,
  INIT15 = 5'd15,
  INIT16 = 5'd16,
  INIT17 = 5'd17,
  INIT18 = 5'd18,
  IDLE = 5'd19,
  READ1 = 5'd20,
  READ2 = 5'd21,
  READ3 = 5'd22,
  READ4 = 5'd23,
  READ5 = 5'd24,
  READ6 = 5'd25,
  WRITE1 = 5'd26,
  WRITE2 = 5'd27,
  WRITE3 = 5'd28,
  WRITE4 = 5'd29,
  WRITE5 = 5'd30;

assign psram_out = psram_data[31:28];

always @ (negedge mem_clk) begin
  if (reset) begin
    mem_wr_sync <= 1'b0;
    mem_rd_sync <= 1'b0;
    state <= STARTUP;
    cache_addr <= 2'd0;
    cache_en <= 1'b0;
    cache_wdata <= 128'd0;
    cache_we <= 1'b0;
    wr_busy <= 1'b0;
    rd_busy <= 1'b0;
    pscnt <= 14'd0;
    psram_ce <= 1'b1;
    psram_oe <= 1'b1;
    psram_data <= 32'd0;
    psram_bitcnt <= 7'd0;
    high_nybble <= 4'd0;
    id_reg <= 64'd0;
  end else begin
    mem_wr_sync <= mem_wr;
    mem_rd_sync <= mem_rd;
    state <= next_state;
    cache_addr <= next_cache_addr;
    cache_en <= next_cache_en;
    cache_wdata <= next_cache_wdata;
    cache_we <= next_cache_we;
    wr_busy <= next_wr_busy;
    rd_busy <= next_rd_busy;
    pscnt <= next_pscnt;
    psram_ce <= next_psram_ce;
    psram_oe <= next_psram_oe;
    psram_data <= next_psram_data;
    psram_bitcnt <= next_psram_bitcnt;
    high_nybble <= next_high_nybble;
    id_reg <= next_id_reg;
  end
end

always @* begin
  next_state = state;
  next_cache_addr = cache_en ? cache_addr + 1'b1 : cache_addr;
  next_cache_wdata = cache_wdata;
  next_cache_en = 1'b0;
  next_cache_we = 1'b0;
  next_wr_busy = wr_busy;
  next_rd_busy = rd_busy;
  next_pscnt = pscnt;
  next_psram_ce = psram_ce;
  next_psram_oe = psram_oe;
  next_psram_data = psram_data;
  next_psram_bitcnt = psram_bitcnt;
  next_high_nybble = high_nybble;
  next_id_reg = id_reg;
  case(state)
    STARTUP: begin
      next_wr_busy = 1'b0;
      next_rd_busy = 1'b0;
      next_psram_ce = 1'b1;
      next_psram_oe = 1'b1;
      next_psram_data = 32'd0;
      next_pscnt = pscnt + 1'b1;
      if (pscnt == 14'd16383)
        next_state = INIT1;
    end
    INIT1: begin
      next_psram_ce = 1'b0;
      next_psram_oe = 1'b0;
      next_psram_data = 32'h01100110;
      next_psram_bitcnt = 7'd0;
      next_state = INIT2;
    end
    INIT2: begin
      next_psram_data = {psram_data[27:0], 4'd0};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd7) begin
        next_psram_ce = 1'b1;
        next_psram_oe = 1'b1;
        next_state = INIT3;
      end
    end
    INIT3: begin
      next_state = INIT4;
    end
    INIT4: begin
      next_psram_ce = 1'b0;
      next_psram_oe = 1'b0;
      next_psram_data = 32'h10011001;
      next_psram_bitcnt = 7'd0;
      next_state = INIT5;
    end
    INIT5: begin
      next_psram_data = {psram_data[27:0], 4'd0};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd7) begin
        next_psram_ce = 1'b1;
        next_psram_oe = 1'b1;
        next_state = INIT6;
      end
    end
    INIT6: begin
      next_state = INIT7;
    end
    INIT7: begin
      next_psram_ce = 1'b0;
      next_psram_oe = 1'b0;
      next_psram_data = 32'h10011111;
      next_psram_bitcnt = 7'd0;
      next_state = INIT8;
    end
    INIT8: begin
      next_psram_data = {psram_data[27:0], 4'd0};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[4:0] == 5'd31) begin
        next_psram_oe = 1'b1;
        next_psram_bitcnt = 7'd0;
        next_id_reg = 64'd0;
        next_state = INIT9;
      end
    end
    INIT9: begin
      next_id_reg = {id_reg[62:0], psram_in[1]};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt == 7'd63) begin
        next_psram_ce = 1'b1;
        next_psram_bitcnt = 7'd0;
        next_state = INIT10;
      end
    end
    INIT10: begin
      next_state = INIT11;
    end
    INIT11: begin
      next_psram_ce = 1'b0;
      next_psram_oe = 1'b0;
      next_psram_data = 32'h00110101;
      next_psram_bitcnt = 7'd0;
      next_state = INIT12;
    end
    INIT12: begin
      next_psram_data = {psram_data[27:0], 4'd0};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd7) begin
        next_psram_ce = 1'b1;
        next_psram_oe = 1'b1;
        next_state = INIT13;
      end
    end
    INIT13: begin
      next_state = IDLE;
    end
    IDLE: begin
      next_wr_busy = 1'b0;
      next_rd_busy = 1'b0;
      if (mem_wr_sync) begin
        next_wr_busy = 1'b1;
        next_cache_en = 1'b1;
        next_cache_addr = 2'd0;
        next_psram_ce = 1'b0;
        next_psram_oe = 1'b0;
        next_psram_data = {8'h38, waddr, 6'd0};
        next_psram_bitcnt = 7'd0;
        next_state = WRITE1;
      end else if (mem_rd_sync) begin
        next_rd_busy = 1'b1;
        next_cache_addr = 2'd0;
        next_psram_ce = 1'b0;
        next_psram_oe = 1'b0;
        next_psram_data = {8'heb, raddr, 6'd0};
        next_psram_bitcnt = 7'd0;
        next_state = READ1;
      end
    end
    READ1: begin
      next_psram_data = {psram_data[27:0], 4'd0};
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd7) begin
        next_psram_bitcnt = 7'd0;
        next_psram_oe = 1'b1;
        next_state = READ2;
      end
    end
    READ2: begin
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd5) begin
        next_psram_bitcnt = 7'd0;
        next_state = READ3;
      end
    end
    READ3: begin
      if (psram_bitcnt[0])
        next_cache_wdata = {high_nybble, psram_in, cache_wdata[127:8]};
      else
        next_high_nybble = psram_in;
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[4:0] == 5'd31) begin
        next_cache_en = 1'b1;
        next_cache_we = 1'b1;
      end
      if (psram_bitcnt == 7'd127) begin
        next_psram_ce = 1'b1;
        next_psram_bitcnt = 7'd0;
        next_state = IDLE;
      end
    end

    WRITE1: begin
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt[2:0] == 3'd7) begin
        next_psram_data = {cache_rdata[7:0], cache_rdata[15:8], cache_rdata[23:16], cache_rdata[31:24]};
        next_psram_bitcnt = 7'd0;
        next_state = WRITE2;
      end else begin
        next_psram_data = {psram_data[27:0], 4'd0};
      end
    end
    WRITE2: begin
      next_psram_bitcnt = psram_bitcnt + 1'b1;
      if (psram_bitcnt == 7'd127) begin
        next_psram_ce = 1'b1;
        next_psram_oe = 1'b1;
        next_state = IDLE;
      end else begin
        if (psram_bitcnt[2:0] < 3'd7)
          next_psram_data = {psram_data[27:0], 4'd0};
        else if (psram_bitcnt[4:3] == 2'b00)
          next_psram_data = {cache_rdata[39:32], cache_rdata[47:40], cache_rdata[55:48], cache_rdata[63:56]};
        else if (psram_bitcnt[4:3] == 2'b01)
          next_psram_data = {cache_rdata[71:64], cache_rdata[79:72], cache_rdata[87:80], cache_rdata[95:88]};
        else if (psram_bitcnt[4:3] == 2'b10)
          next_psram_data = {cache_rdata[103:96], cache_rdata[111:104], cache_rdata[119:112], cache_rdata[127:120]};
        else 
          next_psram_data = {cache_rdata[7:0], cache_rdata[15:8], cache_rdata[23:16], cache_rdata[31:24]};
      end
    end
  endcase
end

endmodule
