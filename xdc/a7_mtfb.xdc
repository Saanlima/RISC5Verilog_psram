
## Clock signal 50 MHz
set_property -dict { PACKAGE_PIN C16    IOSTANDARD LVCMOS33 } [get_ports { sys_clk }];
##create_clock -period 20.000 -name clkin_pin -waveform {0.000 10.000} -add [get_ports sys_clk];
create_clock -period 31.250 -name clkin_pin -waveform {0.000 15.625} -add [get_ports sys_clk]

## FPGA LEDS
set_property -dict { PACKAGE_PIN U1     IOSTANDARD LVCMOS33 } [get_ports { LED1 }];
set_property -dict { PACKAGE_PIN T1     IOSTANDARD LVCMOS33 } [get_ports { LED2 }];

## DVI
set_property -dict { PACKAGE_PIN K2     IOSTANDARD TMDS_33 }  [get_ports { TMDS[0]  }];
set_property -dict { PACKAGE_PIN L2     IOSTANDARD TMDS_33 }  [get_ports { TMDSB[0] }];
set_property -dict { PACKAGE_PIN J3     IOSTANDARD TMDS_33 }  [get_ports { TMDS[1]  }];
set_property -dict { PACKAGE_PIN K3     IOSTANDARD TMDS_33 }  [get_ports { TMDSB[1] }];
set_property -dict { PACKAGE_PIN M2     IOSTANDARD TMDS_33 }  [get_ports { TMDS[2]  }];
set_property -dict { PACKAGE_PIN M1     IOSTANDARD TMDS_33 }  [get_ports { TMDSB[2] }];
set_property -dict { PACKAGE_PIN H2     IOSTANDARD TMDS_33 }  [get_ports { TMDS[3]  }];
set_property -dict { PACKAGE_PIN J2     IOSTANDARD TMDS_33 }  [get_ports { TMDSB[3] }];

## SD CARD
set_property -dict { PACKAGE_PIN A16    IOSTANDARD LVCMOS33 } [get_ports { SS[0]   }];
set_property -dict { PACKAGE_PIN B16    IOSTANDARD LVCMOS33 } [get_ports { MOSI[0] }];
set_property -dict { PACKAGE_PIN A14    IOSTANDARD LVCMOS33 } [get_ports { MISO[0] }];
set_property -dict { PACKAGE_PIN A15    IOSTANDARD LVCMOS33 } [get_ports { SCLK[0] }];
set_property PULLUP true [get_ports MISO[0]]

## nRF24
set_property -dict { PACKAGE_PIN W4     IOSTANDARD LVCMOS33 } [get_ports { SS[1]   }];
set_property -dict { PACKAGE_PIN W3     IOSTANDARD LVCMOS33 } [get_ports { MOSI[1] }];
set_property -dict { PACKAGE_PIN V3     IOSTANDARD LVCMOS33 } [get_ports { MISO[1] }];
set_property -dict { PACKAGE_PIN U3     IOSTANDARD LVCMOS33 } [get_ports { SCLK[1] }];
set_property -dict { PACKAGE_PIN V4     IOSTANDARD LVCMOS33 } [get_ports { NEN     }];
set_property PULLUP true [get_ports MISO[1]]


## UART
set_property -dict { PACKAGE_PIN G18    IOSTANDARD LVCMOS33 } [get_ports { RxD }]; #LVDS0+
set_property -dict { PACKAGE_PIN G17    IOSTANDARD LVCMOS33 } [get_ports { TxD }]; #LVDS1-
set_property PULLUP true [get_ports RxD];

## KBD
set_property -dict { PACKAGE_PIN J17    IOSTANDARD LVCMOS33 } [get_ports { PS2D }]; #LVDS2+
set_property -dict { PACKAGE_PIN K17    IOSTANDARD LVCMOS33 } [get_ports { PS2C }]; #LVDS3-
set_property PULLUP true [get_ports PS2D];
set_property PULLUP true [get_ports PS2C];

## MOUSE
set_property -dict { PACKAGE_PIN L17    IOSTANDARD LVCMOS33 } [get_ports { msdat}]; #LVDS3+
set_property -dict { PACKAGE_PIN P17    IOSTANDARD LVCMOS33 } [get_ports { msclk}]; #LVDS4-
set_property PULLUP true [get_ports msdat];
set_property PULLUP true [get_ports msclk];

## DIP SWITCH
set_property -dict { PACKAGE_PIN N17    IOSTANDARD LVCMOS33 } [get_ports { swi[0] }]; #LVDS4+
set_property -dict { PACKAGE_PIN R18    IOSTANDARD LVCMOS33 } [get_ports { swi[1] }]; #LVDS5-
set_property -dict { PACKAGE_PIN P18    IOSTANDARD LVCMOS33 } [get_ports { swi[2] }]; #LVDS5+
set_property -dict { PACKAGE_PIN T18    IOSTANDARD LVCMOS33 } [get_ports { swi[3] }]; #LVDS6-
set_property PULLDOWN true [get_ports swi[0]];
set_property PULLDOWN true [get_ports swi[1]];
set_property PULLDOWN true [get_ports swi[2]];
set_property PULLDOWN true [get_ports swi[3]];

## SWITCH
set_property -dict { PACKAGE_PIN T17    IOSTANDARD LVCMOS33 } [get_ports { SWITCH }]; #LVDS6+
set_property PULLDOWN true [get_ports SWITCH];

## LEDS
set_property -dict { PACKAGE_PIN U18    IOSTANDARD LVCMOS33 } [get_ports { leds[7] }]; #LVDS7-
set_property -dict { PACKAGE_PIN U17    IOSTANDARD LVCMOS33 } [get_ports { leds[6] }]; #LVDS7+
set_property -dict { PACKAGE_PIN V17    IOSTANDARD LVCMOS33 } [get_ports { leds[5] }]; #LVDS8-
set_property -dict { PACKAGE_PIN V16    IOSTANDARD LVCMOS33 } [get_ports { leds[4] }]; #LVDS8+
set_property -dict { PACKAGE_PIN U16    IOSTANDARD LVCMOS33 } [get_ports { leds[3] }]; #LVDS9-
set_property -dict { PACKAGE_PIN U15    IOSTANDARD LVCMOS33 } [get_ports { leds[2] }]; #LVDS9+
set_property -dict { PACKAGE_PIN V14    IOSTANDARD LVCMOS33 } [get_ports { leds[1] }]; #LVDS10-
set_property -dict { PACKAGE_PIN V13    IOSTANDARD LVCMOS33 } [get_ports { leds[0] }]; #LVDS10+

## SD LED
set_property -dict { PACKAGE_PIN W13    IOSTANDARD LVCMOS33 } [get_ports { LED5   }]; #LVDS11+

## GPIO
set_property -dict { PACKAGE_PIN W14    IOSTANDARD LVCMOS33 } [get_ports { gpio[7] }]; #LVDS11-
set_property -dict { PACKAGE_PIN V15    IOSTANDARD LVCMOS33 } [get_ports { gpio[6] }]; #LVDS12+
set_property -dict { PACKAGE_PIN W15    IOSTANDARD LVCMOS33 } [get_ports { gpio[5] }]; #LVDS12-
set_property -dict { PACKAGE_PIN W16    IOSTANDARD LVCMOS33 } [get_ports { gpio[4] }]; #LVDS13+
set_property -dict { PACKAGE_PIN W17    IOSTANDARD LVCMOS33 } [get_ports { gpio[3] }]; #LVDS13-
set_property -dict { PACKAGE_PIN W18    IOSTANDARD LVCMOS33 } [get_ports { gpio[2] }]; #LVDS14+
set_property -dict { PACKAGE_PIN W19    IOSTANDARD LVCMOS33 } [get_ports { gpio[1] }]; #LVDS14-
set_property -dict { PACKAGE_PIN U19    IOSTANDARD LVCMOS33 } [get_ports { gpio[0] }]; #LVDS15+

## PSRAM
set_property -dict { PACKAGE_PIN M18    IOSTANDARD LVCMOS33 } [get_ports { psram_ce   }]; #LVDS18+
set_property -dict { PACKAGE_PIN M19    IOSTANDARD LVCMOS33 } [get_ports { psram_sio3 }]; #LVDS18-
set_property -dict { PACKAGE_PIN L18    IOSTANDARD LVCMOS33 } [get_ports { psram_sio1 }]; #LVDS19+
set_property -dict { PACKAGE_PIN K18    IOSTANDARD LVCMOS33 } [get_ports { psram_sclk }]; #LVDS19-
set_property -dict { PACKAGE_PIN H19    IOSTANDARD LVCMOS33 } [get_ports { psram_sio2 }]; #LVDS20+
set_property -dict { PACKAGE_PIN G19    IOSTANDARD LVCMOS33 } [get_ports { psram_sio0 }]; #LVDS20-


##set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports spi_ss]
##set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
##set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports spi_miso]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


