
# FPGA settings
FPGA_PART = xc7a50ticpg236-1L
FPGA_TOP = risc5top
FPGA_ARCH = Artix7

# Files for synthesis
SYN_FILES = rtl/RISC5Top.v
SYN_FILES += rtl/BRAM.v
SYN_FILES += rtl/cache_64k.v
SYN_FILES += rtl/Divider.v
SYN_FILES += rtl/DVI.v
SYN_FILES += rtl/encode.v
SYN_FILES += rtl/FPAdder.v
SYN_FILES += rtl/FPDivider.v
SYN_FILES += rtl/FPMultiplier.v
SYN_FILES += rtl/LeftShifter.v
SYN_FILES += rtl/MousePM.v
SYN_FILES += rtl/Multiplier.v
SYN_FILES += rtl/PROM.v
SYN_FILES += rtl/PSRAM.v
SYN_FILES += rtl/PS2.v
SYN_FILES += rtl/Registers.v
SYN_FILES += rtl/RightShifter.v
SYN_FILES += rtl/RISC5.v
SYN_FILES += rtl/RS232R.v
SYN_FILES += rtl/RS232T.v
SYN_FILES += rtl/serialiser_10_to_1.v
SYN_FILES += rtl/SPI.v
SYN_FILES += rtl/VID.v
SYN_FILES += rtl/VRAM.v


# XDC files
XDC_FILES = xdc/a7_mtfb.xdc
#XDC_FILES += xdc/clocks.xdc

# IP
XCI_FILES = 

ifeq ($(OS), Windows_NT)
  VIVADO = C:\Xilinx\Vivado\2017.2\bin\vivado
else
  VIVADO = /opt/Xilinx/Vivado/2017.2/bin/vivado
endif

include ../vivado.mk


