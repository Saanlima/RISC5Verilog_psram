`timescale 1ns / 1ps  // 22.9.2015
// with SRAM, byte access, flt.-pt., and gpio
// PS/2 mouse and network 7.1.2014 PDR

module RISC5Top(
  input sys_clk,
  input SWITCH,
  input  RxD,
  output TxD,
  input [1:0] MISO,
  output [1:0] SCLK, MOSI,
  output [1:0] SS,
  output NEN,
  output [3:0] TMDS,
  output [3:0] TMDSB,
  input PS2C, PS2D,    // keyboard
  inout msclk, msdat,  // mouse
  output LED1,
  output LED2,
  output LED5,
  input [3:0] swi,
  output [7:0] leds,
  inout [7:0] gpio,
  output psram_ce,
  output psram_sclk,
  inout psram_sio0,
  inout psram_sio1,
  inout psram_sio2,
  inout psram_sio3
  );

// IO addresses for input / output
// 0  milliseconds / --
// 1  switches / LEDs
// 2  RS-232 data / RS-232 data (start)
// 3  RS-232 status / RS-232 control
// 4  SPI data / SPI data (start)
// 5  SPI status / SPI control
// 6  PS2 keyboard / --
// 7  mouse / --
// 8  general-purpose I/O data
// 9  general-purpose I/O tri-state control

wire [3:0] btn = {SWITCH, 3'b000};

wire[23:0] adr;
wire [3:0] iowadr;           // word address
wire [31:0] inbus, inbus0;   // data to RISC core
wire [31:0] outbus;          // data from RISC core
wire [31:0] romout, codebus; // code to RISC core
wire rd, wr, ben, ioenb;

wire [7:0] dataTx, dataRx, dataKbd;
wire rdyRx, doneRx, startTx, rdyTx, rdyKbd, doneKbd;
wire [27:0] dataMs;
reg bitrate;  // for RS232
wire limit;   // of cnt0

reg [7:0] Lreg;
reg [15:0] cnt0;
reg [31:0] cnt1; // milliseconds

wire [31:0] spiRx;
wire spiStart, spiRdy;
reg [3:0] spiCtrl;

reg [23:0] display;
wire [23:0] vram_base;
wire vram_access;
wire [31:0] vram_rdata;

wire [14:0] vidadr;
wire [31:0] viddata;

wire bram_access;
wire mreq;

reg [7:0] gpout, gpoc;
wire [7:0] gpin;

wire [2:0] RGB;
wire hsync, vsync, vde;

wire clkfbout, pllclk0, pllclk1, pllclk2, pllclk3;
wire pll_locked;
wire clk, pclk, pclkx5, mem_clk;
reg rst;
wire [3:0] ram_be;

wire [31:0] cache_out, bram_out;
wire [127:0] cache_rdata, cache_wdata;
wire [23:6] waddr, raddr;
wire mem_rd, mem_wr;
wire cache_en;
wire cache_we;
wire [1:0] cache_addr;
wire wr_busy, rd_busy;
wire [63:0] id_reg;

MMCME2_BASE #(
  .BANDWIDTH("OPTIMIZED"),
  .CLKIN1_PERIOD(31.25),
  .CLKFBOUT_MULT_F(25.0),
  .CLKOUT0_DIVIDE_F(16.0)
  ) MMCME2_pre_inst(
  .CLKOUT0(clk50),
  .CLKFBOUT(fbout),
  .LOCKED(locked),
  .CLKIN1(sys_clk),
  .PWRDWN(1'b0),
  .RST(1'b0),
  .CLKFBIN(fbout)
  );

MMCME2_BASE #(
  .BANDWIDTH("OPTIMIZED"),
  .CLKIN1_PERIOD(20.0),
  .CLKFBOUT_MULT_F(15.0),
  .CLKOUT0_DIVIDE_F(7.5),
  .CLKOUT1_DIVIDE(2),
  .CLKOUT2_DIVIDE(10),
  .CLKOUT3_DIVIDE(30)
  ) MMCME2_BASE_inst(
  .CLKOUT0(pllclk0),   // 100 MHz
  .CLKOUT1(pllclk1),   // 375 MHz
  .CLKOUT2(pllclk2),   // 75 MHz
  .CLKOUT3(pllclk3),   // 25 MHz
  .CLKFBOUT(clkfbout),
  .LOCKED(pll_locked),
  .CLKIN1(clk50),
  .PWRDWN(1'b0),
  .RST(1'b0),
  .CLKFBIN(clkfbout)
  );

BUFG pclkx5bufg (.I(pllclk1), .O(pclkx5));
BUFG pclkbufg (.I(pllclk2), .O(pclk));
BUFG clk25buf(.I(pllclk3), .O(clk));
BUFG clk100buf(.I(pllclk0), .O(mem_clk));

RISC5 riscx(.clk(clk), .rst(rst), .ce(ce), .irq(limit),
   .rd(rd), .wr(wr), .ben(ben), .stallX(1'b0),
   .adr(adr), .codebus(codebus), .inbus(inbus),
   .outbus(outbus));

PROM PM (.adr(adr[10:2]), .data(romout), .clk(~clk));

RS232R receiver(.clk(clk), .rst(rst), .RxD(RxD), .fsel(bitrate), .done(doneRx),
   .data(dataRx), .rdy(rdyRx));

RS232T transmitter(.clk(clk), .rst(rst), .start(startTx), .fsel(bitrate),
   .data(dataTx), .TxD(TxD), .rdy(rdyTx));

SPI spi(.clk(clk), .rst(rst), .start(spiStart), .dataTx(outbus),
   .fast(spiCtrl[2]), .dataRx(spiRx), .rdy(spiRdy),
   .SCLK(SCLK[0]), .MOSI(MOSI[0]), .MISO(MISO[0] & MISO[1]));

VID vid(.pclk(pclk), .clk(clk), .req(), .inv(swi[3]), .vidadr(vidadr),
   .viddata(viddata), .RGB(RGB), .hsync(hsync), .vsync(vsync), .vde(vde));

PS2 kbd(.clk(clk), .rst(rst), .done(doneKbd), .rdy(rdyKbd), .shift(),
   .data(dataKbd), .PS2C(PS2C), .PS2D(PS2D));

MousePM Ms(.clk(clk), .rst(rst), .msclk(msclk), .msdat(msdat), .out(dataMs));

DVI dvi(.clkx1(pclk), .clkx5(pclkx5), .pll_reset(~pll_locked),
   .reset(~pll_locked), .red_in({8{RGB[2]}}), .green_in({8{RGB[1]}}), .blue_in({8{RGB[0]}}),
   .hsync(hsync), .vsync(vsync), .vde(vde), .TMDS(TMDS), .TMDSB(TMDSB));

VRAM vram(.clka(~clk), .adra(vram_base[16:2]), .bea(ram_be), .wea(wr & vram_access),
   .wda(outbus), .rda(vram_rdata), .clkb(~clk), .adrb(vidadr),
   .rdb(viddata));

BRAM bram(.clka(~clk), .adra(adr[16:2]), .bea(ram_be), .wea(wr & bram_access),
   .wda(outbus), .rda(bram_out));

assign inbus0 = bram_access ? bram_out : cache_out;
assign codebus = adr[23:12] == 12'hFFE ? romout : inbus0;
assign iowadr = adr[5:2];
assign ioenb = (adr[23:6] == 18'h3FFFF);
assign vram_base = adr[23:0] - display;
assign vram_access = (vram_base[23:17] == 7'h0) & 
                     ((vram_base[16] == 1'b0) | (vram_base[15] == 1'b0));
assign bram_access = (adr[23:17] == 7'h0);
assign mreq = (adr[23] != 1'b1) & ~vram_access & ~bram_access;

assign inbus = (~ioenb & ~vram_access) ? codebus : (~ioenb & vram_access ? vram_rdata :
   ((iowadr == 0) ? cnt1 :
    (iowadr == 1) ? {20'b0, btn, swi[3], 4'b0, swi[2:0]} :
    (iowadr == 2) ? {24'b0, dataRx} :
    (iowadr == 3) ? {30'b0, rdyTx, rdyRx} :
    (iowadr == 4) ? spiRx :
    (iowadr == 5) ? {31'b0, spiRdy} :
    (iowadr == 6) ? {3'b0, rdyKbd, dataMs} :
    (iowadr == 7) ? {24'b0, dataKbd} :
    (iowadr == 8) ? {24'b0, gpin} :
    (iowadr == 9) ? {24'b0, gpoc} :
    (iowadr == 15) ? {8'b0, display} :
    0));

assign ram_be[0] = ~ben | (~adr[1] & ~adr[0]);
assign ram_be[1] = ~ben | (~adr[1] & adr[0]);
assign ram_be[2] = ~ben | (adr[1] & ~adr[0]);
assign ram_be[3] = ~ben | (adr[1] & adr[0]);

genvar i;
generate // tri-state buffer for gpio port
  for (i = 0; i < 8; i = i+1)
  begin: gpioblock
    IOBUF gpiobuf (.I(gpout[i]), .O(gpin[i]), .IO(gpio[i]), .T(~gpoc[i]));
  end
endgenerate

assign dataTx = outbus[7:0];
assign startTx = wr & ioenb & (iowadr == 2);
assign doneRx = rd & ioenb & (iowadr == 2);
assign limit = (cnt0 == 24999);
assign spiStart = wr & ioenb & (iowadr == 4);
assign SS = ~spiCtrl[1:0];  //active low slave select
assign MOSI[1] = MOSI[0], SCLK[1] = SCLK[0], NEN = spiCtrl[3];
assign doneKbd = rd & ioenb & (iowadr == 7);
assign LED1 = wr_busy | rd_busy;
assign LED2 = (id_reg[55:48] != 8'h5d);
assign LED5 = ~SS[0];
assign leds = Lreg;

always @(posedge clk)
begin
  rst <= ((cnt1[4:0] == 0) & limit) ? ~btn[3] : rst;
  Lreg <= ~rst ? 0 : (wr & ioenb & (iowadr == 1)) ? outbus[7:0] : Lreg;
  cnt0 <= limit ? 0 : cnt0 + 1;
  cnt1 <= cnt1 + limit;
  spiCtrl <= ~rst ? 0 : (wr & ioenb & (iowadr == 5)) ? outbus[3:0] : spiCtrl;
  bitrate <= ~rst ? 0 : (wr & ioenb & (iowadr == 3)) ? outbus[0] : bitrate;
  gpout <= (wr & ioenb & (iowadr == 8)) ? outbus[7:0] : gpout;
  gpoc <= ~rst ? 0 : (wr & ioenb & (iowadr == 9)) ? outbus[7:0] : gpoc;
  display <= (wr & ioenb & (iowadr == 15)) ? outbus[23:0] : display;
end

initial
  display = 24'h0e7f00;

cache_64k cache (
  .addr(adr),
  .dout(cache_out), 
  .din(outbus), 
  .clk(clk),
  .mreq(mreq), 
  .wmask(({4{!ben}} | (1'b1 << adr[1:0])) & {4{wr}}),
  .ce(ce), 
  .mem_din(cache_wdata),
  .mem_dout(cache_rdata),
  .mem_clk(mem_clk),
  .mem_rd(mem_rd),
  .mem_wr(mem_wr),
  .waddr(waddr),
  .raddr(raddr),
  .cache_wr(cache_en && cache_we),
  .cache_rd(cache_en && ~cache_we),
  .cache_addr(cache_addr),
  .rd_busy(rd_busy),
  .wr_busy(wr_busy)
);

PSRAM psram(
  .mem_clk(mem_clk),
  .reset(~pll_locked),
  .mem_rd(mem_rd),           // memory read request
  .mem_wr(mem_wr),           // memory write request
  .waddr(waddr),             // memory write address
  .raddr(raddr),             // memory read address
  .cache_rdata(cache_rdata), // write data to memory
  .cache_wdata(cache_wdata), // read data from memory
  .cache_en(cache_en),       // cache eneble
  .cache_we(cache_we),       // cache write
  .cache_addr(cache_addr),   // cache address
  .rd_busy(rd_busy),         // memory controller busy read
  .wr_busy(wr_busy),         // memory controller busy write
  .psram_ce(psram_ce),
  .psram_sclk(psram_sclk),
  .psram_sio0(psram_sio0),
  .psram_sio1(psram_sio1),
  .psram_sio2(psram_sio2),
  .psram_sio3(psram_sio3),
  .id_reg(id_reg)
);



endmodule