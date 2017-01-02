#------------------GLOBAL--------------------#
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name ENABLE_INIT_DONE_OUTPUT OFF

#复位引脚
set_location_assignment	PIN_F2	-to RSTn

#时钟引脚
set_location_assignment	PIN_E15	-to CLK

#EPCS引脚
#set_location_assignment	PIN_H2	-to DATA0
#set_location_assignment	PIN_H1	-to DCLK
#set_location_assignment	PIN_D2	-to SCE
#set_location_assignment	PIN_C1	-to SDO

#SDRAM的引脚
set_location_assignment PIN_N2 -to SDRAM_NE1
set_location_assignment PIN_N1 -to SDRAM_NWE
set_location_assignment PIN_P2 -to SDRAM_NOE
set_location_assignment PIN_L4 -to SDRAM_NBL[1]
set_location_assignment PIN_L1 -to SDRAM_NBL[0]

set_location_assignment PIN_R16 -to SDRAM_DB[15]
set_location_assignment PIN_J13 -to SDRAM_DB[14]
set_location_assignment PIN_P16 -to SDRAM_DB[13]
set_location_assignment PIN_P15 -to SDRAM_DB[12]
set_location_assignment PIN_L14 -to SDRAM_DB[11]
set_location_assignment PIN_K16 -to SDRAM_DB[10]
set_location_assignment PIN_L16 -to SDRAM_DB[9]
set_location_assignment PIN_L15 -to SDRAM_DB[8]
set_location_assignment PIN_N14 -to SDRAM_DB[7]
set_location_assignment PIN_L2 -to SDRAM_DB[6]
set_location_assignment PIN_P6 -to SDRAM_DB[5]
set_location_assignment PIN_J14 -to SDRAM_DB[4]
set_location_assignment PIN_P1 -to SDRAM_DB[3]
set_location_assignment PIN_R1 -to SDRAM_DB[2]
set_location_assignment PIN_N15 -to SDRAM_DB[1]
set_location_assignment PIN_K15 -to SDRAM_DB[0]
set_location_assignment PIN_K5 -to SDRAM_A[15]
set_location_assignment PIN_L3 -to SDRAM_A[14]
set_location_assignment PIN_L13 -to SDRAM_A[13]
set_location_assignment PIN_N16 -to SDRAM_A[12]
set_location_assignment PIN_D1 -to SDRAM_A[11]
set_location_assignment PIN_F8 -to SDRAM_A[10]
set_location_assignment PIN_D3 -to SDRAM_A[9]
set_location_assignment PIN_F9 -to SDRAM_A[8]
set_location_assignment PIN_C2 -to SDRAM_A[7]
set_location_assignment PIN_C3 -to SDRAM_A[6]
set_location_assignment PIN_G2 -to SDRAM_A[5]
set_location_assignment PIN_G1 -to SDRAM_A[4]
set_location_assignment PIN_J2 -to SDRAM_A[3]
set_location_assignment PIN_J1 -to SDRAM_A[2]
set_location_assignment PIN_K2 -to SDRAM_A[1]
set_location_assignment PIN_K1 -to SDRAM_A[0]



##串口1对应的引脚
set_location_assignment	PIN_B4	-to RXD1
set_location_assignment	PIN_A5	-to TXD1
#串口2对应的引脚
set_location_assignment	PIN_B5	-to RXD2
set_location_assignment	PIN_B7	-to TXD2

##PWM输出1-8对应引脚
set_location_assignment	PIN_C11	-to PWM_OUT1
set_location_assignment	PIN_F13	-to PWM_OUT2
set_location_assignment	PIN_F14	-to PWM_OUT3
set_location_assignment	PIN_C14	-to PWM_OUT4
set_location_assignment	PIN_D15	-to PWM_OUT5
set_location_assignment	PIN_C15	-to PWM_OUT6
set_location_assignment	PIN_D16	-to PWM_OUT7
set_location_assignment	PIN_C16	-to PWM_OUT8


#24L01+接口引脚
set_location_assignment	PIN_J16	-to SPI2_MISO
set_location_assignment	PIN_F15	-to SPI2_CLK
set_location_assignment	PIN_F16	-to SPI2_MOSI
set_location_assignment	PIN_B16	-to NRF_CE
set_location_assignment	PIN_A15	-to NRF_CSN
set_location_assignment	PIN_G16	-to NRF_IRQ


#ADNS3080接口引脚
set_location_assignment	PIN_A14	-to SPI1_MISO
set_location_assignment	PIN_A13	-to SPI1_CLK
set_location_assignment	PIN_D14	-to SPI1_MOSI
set_location_assignment	PIN_B14	-to ADNS_CSN
set_location_assignment	PIN_B12	-to ADNS_RST

#I2C_2接口 9150
set_location_assignment	PIN_B10	-to SCL2
set_location_assignment	PIN_A10	-to SDA2

#SPI3接口 5611
set_location_assignment	PIN_D9	-to SPI3_MISO
set_location_assignment	PIN_D8	-to SPI3_CLK
set_location_assignment	PIN_C8	-to SPI3_MOSI
set_location_assignment	PIN_C9	-to BARO_CSN

#PPM接口
set_location_assignment	PIN_J15	-to PPM_IN

#IO接口
set_location_assignment	PIN_E6	-to INT1
set_location_assignment	PIN_D5	-to IO2
set_location_assignment	PIN_E9	-to IO3
set_location_assignment	PIN_B1	-to IO4


